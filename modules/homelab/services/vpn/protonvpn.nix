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
    # Enable systemd-resolved for DNS
    services.resolved.enable = true;
    
    # Install WireGuard tools
    environment.systemPackages = with pkgs; [
      wireguard-tools
      iproute2
    ];
    
    # Create network namespace and start VPN in it
    systemd.services.protonvpn-namespace = {
      description = "ProtonVPN in network namespace";
      after = [ "network-online.target" "systemd-resolved.service" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      
      script = ''
        # Create namespace if it doesn't exist
        ${pkgs.iproute2}/bin/ip netns add ${cfg.namespace} 2>/dev/null || true
        
        # Create veth pair to connect namespace to host
        ${pkgs.iproute2}/bin/ip link add veth-vpn type veth peer name veth-host 2>/dev/null || true
        ${pkgs.iproute2}/bin/ip link set veth-host netns ${cfg.namespace}
        
        # Configure host side
        ${pkgs.iproute2}/bin/ip addr add 10.200.200.1/24 dev veth-vpn
        ${pkgs.iproute2}/bin/ip link set veth-vpn up
        
        # Configure namespace side
        ${pkgs.iproute2}/bin/ip netns exec ${cfg.namespace} ${pkgs.iproute2}/bin/ip addr add 10.200.200.2/24 dev veth-host
        ${pkgs.iproute2}/bin/ip netns exec ${cfg.namespace} ${pkgs.iproute2}/bin/ip link set veth-host up
        ${pkgs.iproute2}/bin/ip netns exec ${cfg.namespace} ${pkgs.iproute2}/bin/ip link set lo up
        
        # Set up DNS in namespace BEFORE starting WireGuard
        mkdir -p /etc/netns/${cfg.namespace}
        cat > /etc/netns/${cfg.namespace}/resolv.conf << EOF
        nameserver 1.1.1.1
        nameserver 8.8.8.8
        EOF
        
        # Enable IP forwarding
        echo 1 > /proc/sys/net/ipv4/ip_forward
        
        # Set up NAT
        ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.200.200.0/24 -o $(${pkgs.iproute2}/bin/ip route | grep default | awk '{print $5}') -j MASQUERADE 2>/dev/null || true
        
        # Add default route in namespace to use veth
        ${pkgs.iproute2}/bin/ip netns exec ${cfg.namespace} ${pkgs.iproute2}/bin/ip route add default via 10.200.200.1
        
        # Create modified WireGuard config without DNS line
        ${pkgs.gnugrep}/bin/grep -v "^DNS" ${cfg.configFile} > /tmp/protonvpn-nodns.conf
        
        # Start WireGuard in namespace with modified config
        ${pkgs.iproute2}/bin/ip netns exec ${cfg.namespace} ${pkgs.wireguard-tools}/bin/wg-quick up /tmp/protonvpn-nodns.conf
      '';
      
      preStop = ''
        ${pkgs.iproute2}/bin/ip netns exec ${cfg.namespace} ${pkgs.wireguard-tools}/bin/wg-quick down /tmp/protonvpn-nodns.conf 2>/dev/null || true
        rm -f /tmp/protonvpn-nodns.conf 2>/dev/null || true
        ${pkgs.iproute2}/bin/ip link del veth-vpn 2>/dev/null || true
        ${pkgs.iproute2}/bin/ip netns del ${cfg.namespace} 2>/dev/null || true
        rm -rf /etc/netns/${cfg.namespace} 2>/dev/null || true
      '';
    };
  };
}
