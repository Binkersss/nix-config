{ config, pkgs, ... }:
{
  imports = [
    ../programs/packages
  ];

  # Wayland session variables
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";  # Hint electron apps to use Wayland
  };
}
