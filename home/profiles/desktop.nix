{
  config,
  pkgs,
  ...
}: {
  imports = [
    ../programs/packages
    ../programs/profiles/niri.nix
    ../programs/profiles/noctalia.nix
  ];

  # Wayland session variables
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # Hint electron apps to use Wayland
  };
}
