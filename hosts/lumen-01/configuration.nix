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
  networking.firewall.checkReversePath = false;
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
 
   # Cloudflare Tunnel service
  services.cloudflared = {
    enable = true;
    tunnels = {
      "chpldev" = {
        credentialsFile = "/root/.cloudflared/1978f09f-9c6e-4bea-aa61-91bef93691e4.json";
        default = "http_status:404";
        ingress = {
          "chappelle.dev" = "http://localhost:8080";
	  "webhook.chappelle.dev" = "http://localhost:9000";
        };
      };
    };
  };

  systemd.services.chpldev-site = {
    description = "Chappelle.dev server";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    
    path = with pkgs; [ go gcc ];
    
    serviceConfig = {
      Type = "simple";
      User = "binker";
      WorkingDirectory = "/home/binker/chpldev";
      Environment = "CGO_ENABLED=0";
      ExecStart = "${pkgs.go}/bin/go run main.go";
      Restart = "always";
      RestartSec = 5;
    };
  };

  systemd.services.chpldev-deploy = {
    description = "Deploy chpldev site";

    path = with pkgs; [ 
    	git
	systemd
	openssh
    ];

    serviceConfig = {
      Type = "oneshot";
      User = "root";
      WorkingDirectory =  "/home/binker/chpldev";

      ExecStart = pkgs.writeShellScript "chpldev-deploy" ''
        set -e
        git pull origin main
        systemctl restart chpldev-site.service
      '';
    };
  };

  systemd.services.chpldev-webhook = {
    description = "GitHub webhook listener for chpldev";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
  
    path = with pkgs; [
      git
      systemd
      openssh
      netcat
    ];
  
    serviceConfig = {
      Type = "simple";
      User = "root";
  
      ExecStart = pkgs.writeShellScript "webhook-listener" ''
        while true; do
          {
            printf "HTTP/1.1 200 OK\r\n"
            printf "Content-Length: 2\r\n"
            printf "Content-Type: text/plain\r\n"
            printf "\r\n"
            printf "OK"
          } | nc -l 9000 
	
	systemctl start chpldev-deploy.service
        done
      '';
  
      Restart = "always";
    };
  };

  # Remove extraRules entirely
  security.sudo.extraRules = [];
  
  # Instead, add a sudoers fragment via environment.etc
  environment.etc."sudoers.d/deployuser".text = ''
    deployuser ALL=(root) NOPASSWD: /bin/systemctl restart chpldev-deploy.service
    deployuser ALL=(root) NOPASSWD: /bin/systemctl start chpldev-deploy.service
  '';

  users.groups.nas = { 
    gid = 1000;
  };
  users.users.binker.extraGroups = [ "nas" ];
  users.users.bazarr.extraGroups = [ "nas" ];
  users.users.radarr.extraGroups = [ "nas" "deluge" ];
  users.users.sonarr.extraGroups = [ "nas" "deluge" ];
  users.users.jellyfin.extraGroups = [ "nas" ];
  # users.users.jellyseerr.extraGroups = [ "nas" ];
  users.users.deluge.extraGroups = [ "nas" ];

  systemd.tmpfiles.rules = [
    "d /mnt/usbnas 0775 root nas -"
    "d /mnt/usbnas/downloads/completed 0775 deluge nas -"
    "d /mnt/usbnas/downloads/complete 0775 deluge nas -"
    "d /mnt/usbnas/downloads/complete 0775 radarr nas -"
    "d /mnt/usbnas/downloads/complete 0775 sonarr nas -"
    "d /mnt/usbnas/downloads/incomplete 0775 deluge nas -"
    "d /mnt/usbnas/downloads/incomplete 0775 radarr nas -"
    "d /mnt/usbnas/downloads/incomplete 0775 sonarr nas -"
    "d /mnt/usbnas/downloads 0775 sonarr nas -"
    "d /mnt/usbnas/downloads 0775 radarr nas -"
    "d /mnt/usbnas/media/movies 0775 radarr nas -"
    "d /mnt/usbnas/media/tv 0775 sonarr nas -"
    "d /mnt/usbnas/media/tv 0775 bazarr nas -"
    "d /mnt/usbnas/media/movies 0775 bazarr nas -"
    "d /mnt/usbnas/media/tv 0775 jellyfin nas -"
    "d /mnt/usbnas/media/movies 0775 jellyfin nas -"
    # "d /mnt/usbnas/media/tv 0775 jellyseerr nas -"
    # "d /mnt/usbnas/media/movies 0775 jellyseerr nas -"


  ];

  homelab.services.vpn.wireguard-netns = {
    enable = true;
    configFile = "/root/protonvpn.conf";
    privateIP = "10.2.0.2/32";
    dnsIP = "10.2.0.1";
  };

  homelab.services.deluge = {
    enable = true;
    downloadLocation = "/mnt/usbnas/downloads";
    useVPN = true;
  };

  homelab.services = {
    homepage = {
      enable = true;
    };

    radarr = {
      enable = true;
    };

    jellyfin = { 
      enable = true;
    };
    jellyseerr = { 
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
  };
}
