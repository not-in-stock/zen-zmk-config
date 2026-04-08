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
    zephyrDepsHash = "sha256-10X9jPN7RVAtHTu1i5mIrXOnsARu1pftb3tl0PWBLTo=";

    meta = {
      description = "zen-zmk-config firmware";
      license = nixpkgs.lib.licenses.mit;
      platforms = nixpkgs.lib.platforms.all;
    };
  in {
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      buildKeyboard = zmk-nix.legacyPackages.${system}.buildKeyboard;
      # Patch prospector's display_idle.c — see comment below.
      prospectorPostConfigure = ''
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
      mk = { name, board, shield ? null }: buildKeyboard (
        {
          inherit name src zephyrDepsHash meta board;
          postConfigure = prospectorPostConfigure;
        }
        // (if shield != null then { inherit shield; } else {})
      );
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

      # Settings-reset firmwares — flash these once to wipe BT pairings etc.
      nice_nano_reset = mk {
        name = "nice_nano_reset";
        board = "nice_nano/nrf52840/zmk";
        shield = "settings_reset";
      };
      xiao_reset = mk {
        name = "xiao_reset";
        board = "xiao_ble/nrf52840/zmk";
        shield = "settings_reset";
      };
      zen_left_reset = mk {
        name = "zen_left_reset";
        board = "corneish_zen_left/nrf52840";
        shield = "settings_reset";
      };
      zen_right_reset = mk {
        name = "zen_right_reset";
        board = "corneish_zen_right/nrf52840";
        shield = "settings_reset";
      };

      # Corne-ish Zen halves (HWMv2, lowprokb vendor)
      zen_left = mk {
        name = "zen_left";
        board = "corneish_zen_left/nrf52840";
      };
      zen_right = mk {
        name = "zen_right";
        board = "corneish_zen_right/nrf52840";
      };

      zen = pkgs.linkFarm "zen-zmk-zen" [
        { name = "zen_left.uf2";  path = "${zen_left}/zmk.uf2"; }
        { name = "zen_right.uf2"; path = "${zen_right}/zmk.uf2"; }
      ];

      reset = pkgs.linkFarm "zen-zmk-reset" [
        { name = "nice_nano_reset.uf2";  path = "${nice_nano_reset}/zmk.uf2"; }
        { name = "xiao_reset.uf2";       path = "${xiao_reset}/zmk.uf2"; }
        { name = "zen_left_reset.uf2";   path = "${zen_left_reset}/zmk.uf2"; }
        { name = "zen_right_reset.uf2";  path = "${zen_right_reset}/zmk.uf2"; }
      ];

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
