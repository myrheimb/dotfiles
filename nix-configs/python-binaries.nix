{
  pkgs,
  unstablePkgs,
  python,
  ...
}:

let

  # Pin the interpreter instead of using writePython3Bin, which follows whatever
  # pkgs.python3 happens to be.
  writePythonBin =
    name:
    pkgs.writers.makePythonWriter python python.pkgs python.pythonOnBuildForHost.pkgs "/bin/${name}";

  # runtimeInputs are put on PATH for the script, for tools it shells out to.
  mkPythonBin =
    name: libraries: runtimeInputs: script:
    let
      unwrapped = writePythonBin name {
        inherit libraries;
        doCheck = false;
      } (builtins.readFile script);
    in
    pkgs.runCommand name { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
      mkdir -p $out/bin
      makeWrapper ${unwrapped}/bin/${name} $out/bin/${name} \
        --prefix PATH : ${pkgs.lib.makeBinPath runtimeInputs}
    '';

  pythonBins = [
    (mkPythonBin "securepass" [ ] [ ] ../scripts/securepass.py)
    (mkPythonBin "update-ssh-config" [ ] [
      unstablePkgs.bitwarden-cli
    ] ../scripts/update_ssh_config.py)
  ];

in

{
  environment.systemPackages = pythonBins;
}
