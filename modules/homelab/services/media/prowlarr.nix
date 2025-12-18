{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.homelab.services.prowlarr;
in {
  options.homelab.services.prowlarr = {
    enable = mkEnableOption "Prowlarr indexer manager";
  };

  config = mkIf cfg.enable {
    services.prowlarr = {
      enable = true;
      openFirewall = true;
    };
  };
}
