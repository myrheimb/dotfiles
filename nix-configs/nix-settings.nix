{ pkgs, config, ... }:

{
  # Nix options for derivations to persist garbage collection
  # Also allow compiling x86_64 (Intel) packages
  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
    extra-platforms = x86_64-darwin aarch64-darwin
  '';


  nix.enable = true;
  nix.package = pkgs.nix;
  nix.channel.enable = false;

  system.primaryUser = config.user.name;

  # Symlink identical store paths
  nix.optimise.automatic = true;

  # Run automatic garbage collection in the nix store
  nix.gc.automatic = true;
  nix.gc.interval = {
    Weekday = 6;
    Hour = 9;
    Minute = 15;
  };

  nix.settings = {
    # Enable flakes
    experimental-features = [
      "flakes"
      "nix-command"
    ];
    # The values auto and 0 will use all available cores
    max-jobs = "auto";
    cores = 0;
    trusted-users = [
      "root"
      config.user.name
    ];
    download-buffer-size = 536870912; # 512 MB
    substituters = [
      "https://cache.nixos.org"
      "https://devenv.cachix.org"
      "https://nixpkgs-python.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU="
    ];
  };

  # Enable non-free packages in nixpkgs
  nixpkgs.config.allowUnfree = true;

  nixpkgs.hostPlatform = config.user.system;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;
}
