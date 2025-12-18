{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.homelab.services.radarr;
in {
  options.homelab.services.radarr = {
    enable = mkEnableOption "Radarr movie management";

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/radarr";
      description = "Directory for Radarr data";
    };
  };

  config = mkIf cfg.enable {
    services.radarr = {
      enable = true;
      dataDir = cfg.dataDir;
      openFirewall = true;
    };
  };
}
