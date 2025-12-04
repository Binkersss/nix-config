{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.homelab.services.deluge;
  ns = config.homelab.services.vpn.wireguard-netns.namespace;
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

    # Bind to VPN namespace if enabled
    systemd = mkIf cfg.useVPN {
      services.deluged.bindsTo = [ "netns@${ns}.service" ];
      services.deluged.requires = [ "network-online.target" "${ns}.service" ];
      services.deluged.after = [ "${ns}.service" ];
      services.deluged.serviceConfig.NetworkNamespacePath = [ "/var/run/netns/${ns}" ];

      sockets."deluged-proxy" = {
        enable = true;
        description = "Socket for Proxy to Deluge Daemon";
        listenStreams = [ "58846" ];
        wantedBy = [ "sockets.target" ];
      };

      services."deluged-proxy" = {
        enable = true;
        description = "Proxy to Deluge Daemon in Network Namespace";
        requires = [ "deluged.service" "deluged-proxy.socket" ];
        after = [ "deluged.service" "deluged-proxy.socket" ];
        unitConfig = { JoinsNamespaceOf = "deluged.service"; };
        serviceConfig = {
          User = "deluge";
          Group = "deluge";
          ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd --exit-idle-time=5min 127.0.0.1:58846";
          PrivateNetwork = "yes";
        };
      };
    };
  };
}
