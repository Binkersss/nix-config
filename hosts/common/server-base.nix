{ config, pkgs, ... }:

{
  imports = [
    ./users.nix
  ];

  # Security hardening
  security.sudo.wheelNeedsPassword = true;
  
  # Automatic updates (disabled initially, enable after stable)
  system.autoUpgrade = {
    enable = false;
    allowReboot = false;
    # flake = "github:yourorg/nixos-infra";
  };

  # SSH hardening
  services.openssh = {
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # Basic monitoring
  services.journald.extraConfig = ''
    SystemMaxUse=500M
    MaxRetentionSec=1month
  '';
}
