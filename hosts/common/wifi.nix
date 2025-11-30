{ config, pkgs, ... }:

{
  # Enable NetworkManager for easy WiFi management
  networking.networkmanager.enable = true;
  
  # Ensure user can manage network
  users.users.binker.extraGroups = [ "networkmanager" ];
}
