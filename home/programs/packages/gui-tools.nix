{ config, pkgs, zen-browser, ... }:
{
  home.packages = with pkgs; [
    # Terminal
    ghostty
    
    File manager
    kdePackages.dolphin
    kdePackages.qtwayland  # Required for Dolphin on Wayland
    
    # XWayland support for niri
    xwayland-satellite
  ] ++ [
    # Browser (from flake input)
    zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
