{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    (python313.withPackages (
      ps: with ps; [
        boltons
        uv
      ]
    ))
  ];
}
