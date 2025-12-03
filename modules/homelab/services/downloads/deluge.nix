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
    
    downloadLocation = mkOption {
      type = types.path;
      default = "/mnt/usbnas/downloads";
      description = "Directory for downloaded files";
    };

    web.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Deluge web interface";
    };

    web.port = mkOption {
      type = types.port;
      default = 8112;
      description = "Port for Deluge web interface";
    };

  };

  config = mkIf cfg.enable {
    services.deluge = {
      enable = true;
      dataDir = cfg.dataDir;
      web = {
	enable = cfg.web.enable;
	port = cfg.web.port;
      };
    };
    networking.firewall.allowedTCPPorts = [ cfg.web.port ];

    systemd.tmpfiles.rules = [
      "d ${cfg.downloadLocation} 0775 deluge deluge -"
    ];
  };
}
