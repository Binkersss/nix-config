{ config, pkgs, ... }:
{
  users.users.binker = {
    isNormalUser = true;
    description = "Nathaniel Chappelle";
    extraGroups = [ "networkmanager" "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGsjGdnuCoMMckj1DZlNk64qOmH0lux9iSGCB1m37fHM binker@shard"
    ];
    shell = pkgs.zsh;
  };

  users.users.root.hashedPassword = "!";

}
