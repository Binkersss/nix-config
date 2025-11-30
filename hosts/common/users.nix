{ config, pkgs, ... }:

{
  # Admin user
  users.users.binker = {
    isNormalUser = true;
    description = "Binker (Admin)";
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGsjGdnuCoMMckj1DZlNk64qOmH0lux9iSGCB1m37fHM binker@shard"
    ];
  };

  # Disable root login
  users.users.root.hashedPassword = "!";
}
