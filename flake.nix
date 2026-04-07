{
  description = "zen-zmk-config — local ZMK builds via zmk-nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    zmk-nix = {
      url = "github:lilyinstarlight/zmk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, zmk-nix }: let
    forAllSystems = nixpkgs.lib.genAttrs (nixpkgs.lib.attrNames zmk-nix.packages);

    # Files relevant to a ZMK build — same set as zmk-nix template.
    src = nixpkgs.lib.sourceFilesBySuffices self [
      ".board" ".cmake" ".conf" ".defconfig" ".dts" ".dtsi"
      ".h" ".json" ".keymap" ".overlay" ".shield" ".yml" "_defconfig"
    ];

    # Bumped via `nix run .#update`. Placeholder until first build tells us.
    zephyrDepsHash = "sha256-Hy/Qiv3y87XfQlPiWumZW0V5Beb69t2XxsWmCYxGTdc=";

    meta = {
      description = "zen-zmk-config firmware";
      license = nixpkgs.lib.licenses.mit;
      platforms = nixpkgs.lib.platforms.all;
    };
  in {
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      buildKeyboard = zmk-nix.legacyPackages.${system}.buildKeyboard;
      mk = { name, board, shield }: buildKeyboard {
        inherit name src zephyrDepsHash meta board shield;

        # Patch prospector's display_idle.c — its SYS_INIT callback uses the
        # old `(const struct device *)` signature, which current Zephyr rejects
        # (init_fn expects `int (*)(void)`). Upstream branch
        # `feat/add-display-sleep` hasn't been updated yet.
        # postConfigure runs after `cp westDeps/*` and `west build --cmake-only`,
        # but before the actual ninja compile — which is when this file is read.
        # We're inside the cmake build dir at this point, so the source lives at ../.
        postConfigure = ''
          f=../prospector-zmk-module/boards/shields/prospector_adapter/src/display_idle.c
          if [ -e "$f" ]; then
            substituteInPlace "$f" \
              --replace-quiet \
                "static int display_idle_init(const struct device *unused) {" \
                "static int display_idle_init(void) {" \
              --replace-quiet \
                "ARG_UNUSED(unused);" \
                ""
          fi
        '';
      };
    in rec {
      corne_dongle = mk {
        name = "corne_dongle";
        board = "xiao_ble/nrf52840/zmk";
        shield = "crpd_dongle prospector_adapter";
      };
      corne_central_left = mk {
        name = "corne_central_left";
        board = "nice_nano/nrf52840/zmk";
        shield = "crpd_central_left nice_view_adapter nice_view";
      };
      corne_left = mk {
        name = "corne_left";
        board = "nice_nano/nrf52840/zmk";
        shield = "crpd_left nice_view_adapter nice_view";
      };
      corne_right = mk {
        name = "corne_right";
        board = "nice_nano/nrf52840/zmk";
        shield = "crpd_right nice_view_adapter nice_view";
      };

      # Classic wireless Corne: left half is central, right half is peripheral.
      wireless = pkgs.linkFarm "zen-zmk-wireless" [
        { name = "corne_central_left.uf2"; path = "${corne_central_left}/zmk.uf2"; }
        { name = "corne_right.uf2";        path = "${corne_right}/zmk.uf2"; }
      ];

      # Wired dongle setup: USB dongle + two peripheral halves.
      dongle = pkgs.linkFarm "zen-zmk-dongle" [
        { name = "corne_dongle.uf2"; path = "${corne_dongle}/zmk.uf2"; }
        { name = "corne_left.uf2";   path = "${corne_left}/zmk.uf2"; }
        { name = "corne_right.uf2";  path = "${corne_right}/zmk.uf2"; }
      ];

      default = dongle;

      flash = zmk-nix.packages.${system}.flash.override { firmware = corne_dongle; };
      update = zmk-nix.packages.${system}.update;
    });

    devShells = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      base = zmk-nix.devShells.${system}.default.override {
        extraPackages = [ pkgs.just ];
      };
    in {
      # Drop straight into the user's zsh so their dotfiles (~/.zshrc etc.)
      # are loaded, while keeping the Nix-provided PATH / env from the shell.
      default = base.overrideAttrs (old: {
        shellHook = (old.shellHook or "") + ''
          # Only re-exec into zsh for interactive shells (not `nix develop -c …`).
          if [ -z "$ZEN_ZMK_IN_ZSH" ] && [ -t 0 ] && [ -z "$NIX_DEVELOP_COMMAND" ] \
             && command -v zsh >/dev/null; then
            export ZEN_ZMK_IN_ZSH=1
            exec zsh
          fi
        '';
      });
    });
  };
}
