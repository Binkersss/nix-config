# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."luks-3814ed9e-6071-412b-93d0-5d142531a483".device = "/dev/disk/by-uuid/3814ed9e-6071-412b-93d0-5d142531a483";

  # initrd ssh for remote encryption passphrase
  # boot.initrd.network = {
  #   enable = true;
  #   ssh = {
  #     enable = true;
  #     port = 2222;
  #     authorizedKeys = [
  #       "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGsjGdnuCoMMckj1DZlNk64qOmH0lux9iSGCB1m37fHM binker@shard"
  #     ];
  #     hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
  #   };
  # };

  networking.hostName = "lumen-01"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
    openFirewall = true;
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ 22 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "NixOS Media Server";
        "netbios name" = "nixos";
        "security" = "user";
        "hosts allow" = "192.168.1. 127.0.0.1 localhost";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };
      
      "media" = {
        "path" = "/mnt/usbnas";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "binker";
      };
    };
  };
  
  
  users.groups.media = { };

  homelab.services = {
    radarr = {
      enable = true;
    };

    vpn.protonvpn = {
      enable = true;
      configFile = "/root/protonvpn.conf";
    };

    jellyfin = { 
      enable = true;
    };

    sonarr = {
     enable = true;
    };

    prowlarr = {
     enable = true;
    };

    bazarr = {
      enable = true;
    };
    
    deluge = {
      enable = true;
      downloadLocation = "/mnt/usbnas/downloads";
      useVPN = true;  # Route through VPN
    };
  };

  users.user.radarr.extraGroups = "media";
  users.user.jellyfin.extraGroups = "media";
  users.user.sonarr.extraGroups = "media";
  users.user.prowlarr.extraGroups = "media";
  users.user.bazarr.extraGroups = "media";
  users.user.deluge.extraGroups = "media";
}
