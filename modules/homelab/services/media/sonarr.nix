{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.homelab.services.sonarr;
in {
  options.homelab.services.sonarr = {
    enable = mkEnableOption "Sonarr TV show management";
    
    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/sonarr";
      description = "Directory for Sonarr data";
    };
  };

  config = mkIf cfg.enable {
    services.sonarr = {
      enable = true;
      dataDir = cfg.dataDir;
      openFirewall = true;
    };
  };
}
