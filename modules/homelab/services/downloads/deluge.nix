{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.homelab.services.deluge;
in {
  options.homelab.services.deluge = {
    enable = mkEnableOption "Deluge torrent client";
    
    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/deluge";
      description = "Directory for Deluge data";
    };
    
    web.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Deluge web interface";
    };
  };

  config = mkIf cfg.enable {
    services.deluge = {
      enable = true;
      dataDir = cfg.dataDir;
      web.enable = cfg.web.enable;
      openFirewall = true;
    };
  };
}
