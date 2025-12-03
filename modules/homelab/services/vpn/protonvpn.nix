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
    environment.systemPackages = with pkgs; [
      wireguard-tools
      iproute2
    ];
    
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
        set -e
        
        # Clean up any existing setup
        ${pkgs.iproute2}/bin/ip link del veth-vpn 2>/dev/null || true
        ${pkgs.iproute2}/bin/ip netns del ${cfg.namespace} 2>/dev/null || true
        
        # Create namespace
        ${pkgs.iproute2}/bin/ip netns add ${cfg.namespace}
        
        # Create veth pair
        ${pkgs.iproute2}/bin/ip link add veth-vpn type veth peer name veth-host
        ${pkgs.iproute2}/bin/ip link set veth-host netns ${cfg.namespace}
        
        # Configure host side
        ${pkgs.iproute2}/bin/ip addr add 10.200.200.1/24 dev veth-vpn
        ${pkgs.iproute2}/bin/ip link set veth-vpn up
        
        # Configure namespace side
        ${pkgs.iproute2}/bin/ip -n ${cfg.namespace} addr add 10.200.200.2/24 dev veth-host
        ${pkgs.iproute2}/bin/ip -n ${cfg.namespace} link set veth-host up
        ${pkgs.iproute2}/bin/ip -n ${cfg.namespace} link set lo up
        
        # Add default route in namespace through veth
        ${pkgs.iproute2}/bin/ip -n ${cfg.namespace} route add default via 10.200.200.1
        
        # Enable IP forwarding
        echo 1 > /proc/sys/net/ipv4/ip_forward
        
        # Set up NAT from namespace to host's default interface
        DEFAULT_IF=$(${pkgs.iproute2}/bin/ip route | ${pkgs.gawk}/bin/awk '/default/ {print $5}')
        ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.200.200.0/24 -o "$DEFAULT_IF" -j MASQUERADE 2>/dev/null || true
        ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.200.200.0/24 -o "$DEFAULT_IF" -j MASQUERADE
        
        # Set up DNS before starting WireGuard
        mkdir -p /etc/netns/${cfg.namespace}
        cat > /etc/netns/${cfg.namespace}/resolv.conf << 'EOF'
        nameserver 1.1.1.1
        nameserver 8.8.8.8
        EOF
        
        # Strip DNS from WireGuard config
        ${pkgs.gnused}/bin/sed '/^DNS/d' ${cfg.configFile} > /tmp/protonvpn-nodns.conf
        chmod 600 /tmp/protonvpn-nodns.conf
        
        # Start WireGuard in the namespace
        ${pkgs.iproute2}/bin/ip netns exec ${cfg.namespace} ${pkgs.wireguard-tools}/bin/wg-quick up /tmp/protonvpn-nodns.conf
      '';
      
      preStop = ''
        ${pkgs.iproute2}/bin/ip netns exec ${cfg.namespace} ${pkgs.wireguard-tools}/bin/wg-quick down /tmp/protonvpn-nodns.conf 2>/dev/null || true
        rm -f /tmp/protonvpn-nodns.conf 2>/dev/null || true
        
        # Clean up NAT rule
        DEFAULT_IF=$(${pkgs.iproute2}/bin/ip route | ${pkgs.gawk}/bin/awk '/default/ {print $5}')
        ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.200.200.0/24 -o "$DEFAULT_IF" -j MASQUERADE 2>/dev/null || true
        
        ${pkgs.iproute2}/bin/ip link del veth-vpn 2>/dev/null || true
        ${pkgs.iproute2}/bin/ip netns del ${cfg.namespace} 2>/dev/null || true
        rm -rf /etc/netns/${cfg.namespace} 2>/dev/null || true
      '';
    };
  };
}
