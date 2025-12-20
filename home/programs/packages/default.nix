{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./cli-tools.nix
    ./networking.nix
    ./monitoring.nix
    ./development.nix
    ./gui-tools.nix
    ./gaming.nix
  ];
}
