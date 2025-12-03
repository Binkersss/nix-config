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
    # Create a stripped config file without Address line
    environment.etc."protonvpn-wg.conf" = {
      mode = "0600";
      text = builtins.readFile cfg.configFile;
    };

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

    # setting up wireguard interface within network namespace
    systemd.services."protonvpn-wg" = {
      description = "ProtonVPN WireGuard interface in network namespace";
      bindsTo = [ "netns@${cfg.namespace}.service" ];
      requires = [ "network-online.target" ];
      after = [ "netns@${cfg.namespace}.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = with pkgs; writers.writeBash "protonvpn-wg-up" ''
          set -e
          
          # Create filtered config without Address line
          ${gnugrep}/bin/grep -v '^Address' ${cfg.configFile} > /tmp/protonvpn-wg-filtered.conf
          chmod 600 /tmp/protonvpn-wg-filtered.conf
          
          ${iproute2}/bin/ip link add wg0 type wireguard
          ${iproute2}/bin/ip link set wg0 netns ${cfg.namespace}
          ${iproute2}/bin/ip -n ${cfg.namespace} address add ${cfg.vpnAddress} dev wg0
          ${optionalString (cfg.vpnAddressIPv6 != null) ''
            ${iproute2}/bin/ip -n ${cfg.namespace} -6 address add ${cfg.vpnAddressIPv6} dev wg0
          ''}
          ${iproute2}/bin/ip netns exec ${cfg.namespace} \
            ${wireguard-tools}/bin/wg setconf wg0 /tmp/protonvpn-wg-filtered.conf
          ${iproute2}/bin/ip -n ${cfg.namespace} link set wg0 up
          ${iproute2}/bin/ip -n ${cfg.namespace} link set lo up
          ${iproute2}/bin/ip -n ${cfg.namespace} route add default dev wg0
          ${optionalString (cfg.vpnAddressIPv6 != null) ''
            ${iproute2}/bin/ip -n ${cfg.namespace} -6 route add default dev wg0
          ''}
          
          # Clean up temp file
          rm -f /tmp/protonvpn-wg-filtered.conf
        '';
        ExecStop = with pkgs; writers.writeBash "protonvpn-wg-down" ''
          ${iproute2}/bin/ip -n ${cfg.namespace} route del default dev wg0 || true
          ${optionalString (cfg.vpnAddressIPv6 != null) ''
            ${iproute2}/bin/ip -n ${cfg.namespace} -6 route del default dev wg0 || true
          ''}
          ${iproute2}/bin/ip -n ${cfg.namespace} link del wg0 || true
          rm -f /tmp/protonvpn-wg-filtered.conf
        '';
      };
    };
  };
}
