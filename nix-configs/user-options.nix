{ lib, ... }:

{
  options.user = {
    name = lib.mkOption {
      type = lib.types.str;
      description = "Primary username.";
    };

    hostname = lib.mkOption {
      type = lib.types.str;
      description = "System hostname.";
    };

    system = lib.mkOption {
      type = lib.types.str;
      description = "Nix system (e.g. aarch64-darwin).";
    };
  };
}
