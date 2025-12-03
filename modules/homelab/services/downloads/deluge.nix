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

    # binding deluged to network namespace
    systemd.services.deluged = mkIf cfg.useVPN {
      bindsTo = [ "netns@${vpnCfg.namespace}.service" ];
      requires = [ "network-online.target" "protonvpn-wg.service" ];
      after = [ "protonvpn-wg.service" ];
      serviceConfig.NetworkNamespacePath = [ "/var/run/netns/${vpnCfg.namespace}" ];
    };

    # allowing delugeweb to access deluged in network namespace
    systemd.sockets."proxy-to-deluged" = mkIf cfg.useVPN {
      enable = true;
      description = "Socket for Proxy to Deluge Daemon";
      listenStreams = [ "58846" ];
      wantedBy = [ "sockets.target" ];
    };

    # creating proxy service on socket
    systemd.services."proxy-to-deluged" = mkIf cfg.useVPN {
      enable = true;
      description = "Proxy to Deluge Daemon in Network Namespace";
      requires = [ "deluged.service" "proxy-to-deluged.socket" ];
      after = [ "deluged.service" "proxy-to-deluged.socket" ];
      unitConfig = { JoinsNamespaceOf = "deluged.service"; };
      serviceConfig = {
        User = "deluge";
        Group = "deluge";
        ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd --exit-idle-time=5min 127.0.0.1:58846";
        PrivateNetwork = "yes";
      };
    };
  };
}
