{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.homelab.services.vpn.wireguard-netns;
in {
  options.homelab.services.vpn.wireguard-netns = {
    enable = lib.mkEnableOption "Wireguard client network namespace";

    namespace = lib.mkOption {
      type = lib.types.str;
      description = "Network namespace to be created";
      default = "protonvpn";
    };

    configFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to Wireguard config file";
    };

    privateIP = lib.mkOption {
      type = lib.types.str;
      description = "Private IP address for the interface";
      example = "10.2.0.2/32";
    };

    dnsIP = lib.mkOption {
      type = lib.types.str;
      description = "DNS server IP";
      default = "10.2.0.1";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services."netns@" = {
      description = "%I network namespace";
      before = ["network.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.iproute2}/bin/ip netns add %I";
        ExecStop = "${pkgs.iproute2}/bin/ip netns del %I";
      };
    };

    environment.etc."netns/${cfg.namespace}/resolv.conf".text = "nameserver ${cfg.dnsIP}";

    systemd.services."${cfg.namespace}" = {
      description = "${cfg.namespace} network interface";
      bindsTo = ["netns@${cfg.namespace}.service"];
      requires = ["network-online.target"];
      after = ["netns@${cfg.namespace}.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = with pkgs;
          writers.writeBash "wg-up" ''
            set -e
            # Clean up any existing interface
            ${iproute2}/bin/ip link del wg0 2>/dev/null || true
            ${iproute2}/bin/ip -n ${cfg.namespace} link del wg0 2>/dev/null || true

            # Filter config to remove Address and DNS lines
            ${gnugrep}/bin/grep -vE '^(Address|DNS)' ${cfg.configFile} > /run/${cfg.namespace}-wg.conf
            chmod 600 /run/${cfg.namespace}-wg.conf

            ${iproute2}/bin/ip link add wg0 type wireguard
            ${iproute2}/bin/ip link set wg0 netns ${cfg.namespace}
            ${iproute2}/bin/ip -n ${cfg.namespace} address add ${cfg.privateIP} dev wg0
            ${iproute2}/bin/ip netns exec ${cfg.namespace} \
              ${wireguard-tools}/bin/wg setconf wg0 /run/${cfg.namespace}-wg.conf
            ${iproute2}/bin/ip -n ${cfg.namespace} link set wg0 up
            ${iproute2}/bin/ip -n ${cfg.namespace} link set lo up
            ${iproute2}/bin/ip -n ${cfg.namespace} route add default dev wg0

            rm -f /run/${cfg.namespace}-wg.conf
          '';
        ExecStop = with pkgs;
          writers.writeBash "wg-down" ''
            ${iproute2}/bin/ip -n ${cfg.namespace} route del default dev wg0 2>/dev/null || true
            ${iproute2}/bin/ip -n ${cfg.namespace} link del wg0 2>/dev/null || true
            rm -f /run/${cfg.namespace}-wg.conf
          '';
      };
    };

    systemd.services."${cfg.namespace}-portforward" = {
      description = "Port forwarding for ${cfg.namespace}";
      after = ["${cfg.namespace}.service"];
      requires = ["${cfg.namespace}.service"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "45";
      };

      script = with pkgs; ''
        while true; do
          # Request port forwarding
          PORT=$(${iproute2}/bin/ip netns exec ${cfg.namespace} \
            ${libnatpmp}/bin/natpmpc -a 1 0 udp 60 -g ${cfg.dnsIP} 2>&1 | \
            ${gnugrep}/bin/grep "Mapped public port" | ${gawk}/bin/awk '{print $4}')

          if [ -n "$PORT" ]; then
            echo "Forwarded port: $PORT"
            echo "$PORT" > /run/${cfg.namespace}-port

            # Also request TCP
            ${iproute2}/bin/ip netns exec ${cfg.namespace} \
              ${libnatpmp}/bin/natpmpc -a "$PORT" "$PORT" tcp 60 -g ${cfg.dnsIP} >/dev/null 2>&1 || true
            ${iproute2}/bin/ip netns exec ${cfg.namespace} \
              ${libnatpmp}/bin/natpmpc -a "$PORT" "$PORT" udp 60 -g ${cfg.dnsIP} >/dev/null 2>&1 || true
          else
            echo "Failed to get forwarded port"
          fi

          # Refresh every 45 seconds (lease is 60s)
          sleep 45
        done
      '';
    };
  };
}
