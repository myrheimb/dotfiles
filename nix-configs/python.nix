{
  pkgs,
  lib,
  inputs,
  python,
  ...
}:

let
  inherit (inputs) pyproject-nix uv2nix pyproject-build-systems;

  # Dependencies are declared in ./python-env/pyproject.toml and pinned (with
  # hashes) in ./python-env/uv.lock. Bump them with:
  #   uv lock --upgrade --directory nix-configs/python-env
  workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./python-env; };

  pythonSet =
    (pkgs.callPackage pyproject-nix.build.packages {
      inherit python;
    }).overrideScope
      (lib.composeManyExtensions [
        pyproject-build-systems.overlays.wheel
        (workspace.mkPyprojectOverlay { sourcePreference = "wheel"; })
      ]);

  pythonEnv = pythonSet.mkVirtualEnv "system-python-env" workspace.deps.default;
in

{
  # The one interpreter for the system Python and the scripts in ./python-binaries.nix.
  _module.args.python = pkgs.python314;

  environment.systemPackages = [
    pythonEnv
    pkgs.uv
  ];
}
