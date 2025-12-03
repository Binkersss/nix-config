{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.homelab.services.bazarr;
in {
  options.homelab.services.bazarr = {
    enable = mkEnableOption "Bazarr subtitle management";
  };

  config = mkIf cfg.enable {
    services.bazarr = {
      enable = true;
      openFirewall = true;
    };
  };
}
