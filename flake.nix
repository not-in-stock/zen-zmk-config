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
      ".json" ".keymap" ".overlay" ".shield" ".yml" "_defconfig"
    ];

    # Bumped via `nix run .#update`. Placeholder until first build tells us.
    zephyrDepsHash = nixpkgs.lib.fakeHash;

    meta = {
      description = "zen-zmk-config firmware";
      license = nixpkgs.lib.licenses.mit;
      platforms = nixpkgs.lib.platforms.all;
    };
  in {
    packages = forAllSystems (system: let
      buildKeyboard = zmk-nix.legacyPackages.${system}.buildKeyboard;
      mk = { name, board, shield }: buildKeyboard {
        inherit name src zephyrDepsHash meta board shield;
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

      default = corne_dongle;

      flash = zmk-nix.packages.${system}.flash.override { firmware = corne_dongle; };
      update = zmk-nix.packages.${system}.update;
    });

    devShells = forAllSystems (system: {
      default = zmk-nix.devShells.${system}.default;
    });
  };
}
