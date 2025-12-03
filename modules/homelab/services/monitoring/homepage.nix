{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.homelab.services.homepage;
  serverIP = "10.0.0.222";
in {
  options.homelab.services.homepage = {
    enable = mkEnableOption "Homepage dashboard";
    allowedHosts = 10.0.0.75; 
    port = mkOption {
      type = types.port;
      default = 3000;
      description = "Port for Homepage";
    };
  };

  config = mkIf cfg.enable {
    services.homepage-dashboard = {
      enable = true;
      
      openFirewall = true;
      
      listenPort = cfg.port;
      
      settings = {
        title = "Homelab Dashboard";
        
        layout = [
          {
            Media = {
              style = "row";
              columns = 3;
            };
          }
          {
            Downloads = {
              style = "row";
              columns = 2;
            };
          }
        ];
      };
      
      services = [
        {
          Media = [
            {
              Jellyfin = {
                icon = "jellyfin.png";
                href = "http://${serverIP}:8096";
                description = "Media Server";
              };
            }
            {
              Radarr = {
                icon = "radarr.png";
                href = "http://${serverIP}:7878";
                description = "Movie Management";
              };
            }
            {
              Sonarr = {
                icon = "sonarr.png";
                href = "http://${serverIP}:8989";
                description = "TV Show Management";
              };
            }
            {
              Prowlarr = {
                icon = "prowlarr.png";
                href = "http://${serverIP}:9696";
                description = "Indexer Manager";
              };
            }
            {
              Bazarr = {
                icon = "bazarr.png";
                href = "http://${serverIP}:6767";
                description = "Subtitle Management";
              };
            }
            {
              Jellyseerr = {
                icon = "jellyseerr.png";
                href = "http://${serverIP}:5055";
                description = "Request Management";
              };
            }
          ];
        }
        {
          Downloads = [
            {
              Deluge = {
                icon = "deluge.png";
                href = "http://${serverIP}:8112";
                description = "Torrent Client";
              };
            }
          ];
        }
      ];
      
      widgets = [
        {
          resources = {
            cpu = true;
            memory = true;
            disk = "/";
          };
        }
        {
          search = {
            provider = "duckduckgo";
            target = "_blank";
          };
        }
      ];
      
      bookmarks = [
        {
          Developer = [
            {
              Github = [
                {
                  abbr = "GH";
                  href = "https://github.com/";
                }
              ];
            }
          ];
        }
      ];
    };

    # Override the systemd service to bind to all interfaces
    systemd.services.homepage-dashboard.serviceConfig = {
      Environment = [
        "HOSTNAME=0.0.0.0"
      ];
    };
  };
}
