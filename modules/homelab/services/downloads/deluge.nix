{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.homelab.services.deluge;
  vpnCfg = config.homelab.services.vpn.protonvpn;
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

    useVPN = mkOption {
      type = types.bool;
      default = false;
      description = "Route Deluge through VPN namespace";
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

    # Run Deluge daemon in VPN namespace
    systemd.services.deluged = mkIf cfg.useVPN {
      bindsTo = [ "protonvpn-namespace.service" ];
      after = [ "protonvpn-namespace.service" ];
      serviceConfig = {
        NetworkNamespacePath = "/var/run/netns/${vpnCfg.namespace}";
      };
    };

    systemd.services.delugeweb = mkIf (cfg.web.enable && !cfg.useVPN) {
      # Web UI runs on host network, connects to daemon in namespace
    };
  };
}
