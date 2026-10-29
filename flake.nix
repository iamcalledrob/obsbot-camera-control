{
  description = "Native Linux control app for OBSBOT cameras with PTZ, auto-framing, presets, and live preview";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
  };

  outputs =
    { self, nixpkgs }:
    let
      # The vendored OBSBOT SDK (libdev.so) is only shipped for x86_64.
      systems = [ "x86_64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: {
        obsbot-camera-control = pkgs.callPackage ./nix/package.nix { };
        default = self.packages.${pkgs.stdenv.hostPlatform.system}.obsbot-camera-control;
      });

      overlays.default = final: _prev: {
        obsbot-camera-control = final.callPackage ./nix/package.nix { };
      };

      nixosModules.default = import ./nix/module.nix self;

      apps = forAllSystems (pkgs: {
        default = {
          type = "app";
          program = "${self.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/obsbot-gui";
        };
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          inputsFrom = [ self.packages.${pkgs.stdenv.hostPlatform.system}.default ];
        };
      });
    };
}
