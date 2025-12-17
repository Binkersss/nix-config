{ config, pkgs, ... }:

{
  imports = [
    ./cli-tools.nix
    ./networking.nix
    ./monitoring.nix
    ./development.nix
    ./gui-tools.nix
  ];
}
