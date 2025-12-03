{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.homelab.services.vpn.protonvpn;
in {
  options.homelab.services.vpn.protonvpn = {
    enable = mkEnableOption "ProtonVPN";
    
    namespace = mkOption {
      type = types.str;
      default = "vpn";
      description = "Network namespace name";
    };
    
    configFile = mkOption {
      type = types.path;
      description = "Path to ProtonVPN WireGuard config file";
      example = "/root/protonvpn.conf";
    };
  };

  config = mkIf cfg.enable {
    # Install WireGuard tools
    environment.systemPackages = with pkgs; [
      wireguard-tools
      iproute2
    ];
    
    # Create network namespace and start VPN in it
    systemd.services.protonvpn-namespace = {
      description = "ProtonVPN in network namespace";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      
      script = ''
        # Create namespace
        ${pkgs.iproute2}/bin/ip netns add ${cfg.namespace} || true
        
        # Start WireGuard in namespace
        ${pkgs.iproute2}/bin/ip netns exec ${cfg.namespace} \
          ${pkgs.wireguard-tools}/bin/wg-quick up ${cfg.configFile}
      '';
      
      preStop = ''
        ${pkgs.iproute2}/bin/ip netns exec ${cfg.namespace} \
          ${pkgs.wireguard-tools}/bin/wg-quick down ${cfg.configFile} || true
        ${pkgs.iproute2}/bin/ip netns del ${cfg.namespace} || true
      '';
    };
  };
}
