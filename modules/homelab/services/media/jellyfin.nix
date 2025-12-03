{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.homelab.services.jellyfin;
in {
  options.homelab.services.jellyfin = {
    enable = mkEnableOption "Jellyfin media server";
    
    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/jellyfin";
      description = "Directory for Jellyfin application data";
    };
    
    mediaLocations = mkOption {
      type = types.listOf types.path;
      default = [];
      description = "Directories containing media files";
      example = [ "/mnt/usbnas/media/movies" "/mnt/usbnas/media/tv" ];
    };
  };

  config = mkIf cfg.enable {
    services.jellyfin = {
      enable = true;
      dataDir = cfg.dataDir;
      openFirewall = true;
    };
    
    # Ensure jellyfin user can read media directories
    systemd.tmpfiles.rules = map (dir: 
      "d ${dir} 0755 jellyfin jellyfin -"
    ) cfg.mediaLocations;
  };
}
