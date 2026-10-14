{
  description = "nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      unstable,
      nix-homebrew,
      homebrew-core,
      homebrew-cask,
    }:
    let
      mkDarwin =
        {
          hostname,
          name,
          system ? "aarch64-darwin",
        }:
        nix-darwin.lib.darwinSystem {
          system = system;
          # Make pkgs from unstable available to subsequent config files
          specialArgs = {
            unstablePkgs = import unstable {
              inherit system;
              config = {
                allowUnfree = true;
              };
            };
          };
          modules = [
            ./darwin.nix
            { user = { inherit hostname name system; }; }
            ../user-specific/${name}/config.nix

            nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew = {
                # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
                enableRosetta = true;

                # Declarative tap management
                taps = {
                  "homebrew/homebrew-core" = homebrew-core;
                  "homebrew/homebrew-cask" = homebrew-cask;
                };

                # Enable fully-declarative tap management
                # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
                mutableTaps = false;
              };
            }
            # Align homebrew taps config with nix-homebrew
            (
              { config, ... }:
              {
                homebrew.taps = builtins.attrNames config.nix-homebrew.taps;
              }
            )
          ];
        };
    in
    {
      darwinConfigurations = {
        BearBook = mkDarwin {
          hostname = "BearBook";
          name = "bjoernar.myrheim";
        };
        YekolBook = mkDarwin {
          hostname = "YekolBook";
          name = "yekol";
        };
      };
    };
}
