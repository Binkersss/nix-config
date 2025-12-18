{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.homelab.services.jellyseerr;
in {
  options.homelab.services.jellyseerr = {
    enable = mkEnableOption "Jellyseerr request management";

    port = mkOption {
      type = types.port;
      default = 5055;
      description = "Port for Jellyseerr";
    };
  };

  config = mkIf cfg.enable {
    services.jellyseerr = {
      enable = true;
      port = cfg.port;
      openFirewall = true;
    };
  };
}
