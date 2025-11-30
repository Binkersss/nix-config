{ config, pkgs, lib, ... }:

{
  # Hardware configuration will be imported automatically by nixos-anywhere
  # during installation, so we don't specify it here for initial deploy
  imports = [
    ../common/wifi.nix
  ];

  networking.hostName = "lumen-01";
  
  # Timezone and locale
  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # System packages
  environment.systemPackages = with pkgs; [
    neovim
    wget
    curl
    git
    htop
    tmux
  ];

  # Enable SSH
  services.openssh.enable = true;
  
  # Firewall
  networking.firewall.allowedTCPPorts = [ 22 ];

  system.stateVersion = "24.05";

  boot.initrd.luks.devices.cryptroot = {
    device = "/dev/disk/by-partlabel/root";
    preLVM = true;
  };

}
