{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.homelab.services.vpn.protonvpn;
in
{
  options.homelab.services.vpn.protonvpn = {
    enable = mkEnableOption "ProtonVPN in network namespace";

    configFile = mkOption {
      type = types.path;
      default = /root/protonvpn.conf;
      description = "Path to ProtonVPN WireGuard configuration file";
    };

    vpnAddress = mkOption {
      type = types.str;
      example = "10.2.0.2/32";
      description = "VPN IPv4 address with CIDR from ProtonVPN config";
    };

    vpnAddressIPv6 = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "fd00::1/128";
      description = "VPN IPv6 address with CIDR from ProtonVPN config (optional)";
    };

    namespace = mkOption {
      type = types.str;
      default = "protonvpn";
      description = "Name of the network namespace";
    };
  };

  config = mkIf cfg.enable {
    # creating network namespace
    systemd.services."netns@" = {
      description = "%I network namespace";
      before = [ "network.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.iproute2}/bin/ip netns add %I";
        ExecStop = "${pkgs.iproute2}/bin/ip netns del %I";
      };
    };

    # Ensure the specific namespace instance starts on boot
    systemd.services."netns@${cfg.namespace}" = {
      wantedBy = [ "multi-user.target" ];
    };

    # setting up wireguard interface within network namespace
    systemd.services.protonvpn-wg = {
      description = "ProtonVPN WireGuard interface";
      wantedBy = [ "multi-user.target" ];  # Start on boot
      bindsTo = [ "netns@${cfg.namespace}.service" ];
      requires = [ "network-online.target" ];
      after = [ "netns@${cfg.namespace}.service" "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = with pkgs; writers.writeBash "protonvpn-wg-up" ''
          set -e
          
          # Wait for namespace to be ready
          for i in {1..10}; do
            if ${iproute2}/bin/ip netns list | ${gnugrep}/bin/grep -q "^${cfg.namespace}"; then
              break
            fi
            sleep 0.5
          done
          
          # Clean up any existing interface
          ${iproute2}/bin/ip link del wg0 2>/dev/null || true
          ${iproute2}/bin/ip -n ${cfg.namespace} link del wg0 2>/dev/null || true
          
          # Create filtered config (remove Address line as wg setconf doesn't accept it)
          ${gnugrep}/bin/grep -v '^Address' ${cfg.configFile} > /run/protonvpn-wg.conf
          chmod 600 /run/protonvpn-wg.conf
          
          ${iproute2}/bin/ip link add wg0 type wireguard
          ${iproute2}/bin/ip link set wg0 netns ${cfg.namespace}
          ${iproute2}/bin/ip -n ${cfg.namespace} address add ${cfg.vpnAddress} dev wg0
          ${optionalString (cfg.vpnAddressIPv6 != null) ''
          ${iproute2}/bin/ip -n ${cfg.namespace} -6 address add ${cfg.vpnAddressIPv6} dev wg0
          ''}
          ${iproute2}/bin/ip netns exec ${cfg.namespace} \
            ${wireguard-tools}/bin/wg setconf wg0 /run/protonvpn-wg.conf
          ${iproute2}/bin/ip -n ${cfg.namespace} link set wg0 up
          ${iproute2}/bin/ip -n ${cfg.namespace} link set lo up
          ${iproute2}/bin/ip -n ${cfg.namespace} route add default dev wg0
          ${optionalString (cfg.vpnAddressIPv6 != null) ''
          ${iproute2}/bin/ip -n ${cfg.namespace} -6 route add default dev wg0
          ''}
          
          # Clean up filtered config
          rm -f /run/protonvpn-wg.conf
        '';
        ExecStop = with pkgs; writers.writeBash "protonvpn-wg-down" ''
          ${iproute2}/bin/ip -n ${cfg.namespace} route del default dev wg0 2>/dev/null || true
          ${optionalString (cfg.vpnAddressIPv6 != null) ''
          ${iproute2}/bin/ip -n ${cfg.namespace} -6 route del default dev wg0 2>/dev/null || true
          ''}
          ${iproute2}/bin/ip -n ${cfg.namespace} link del wg0 2>/dev/null || true
          rm -f /run/protonvpn-wg.conf
        '';
      };
    };
  };
}
