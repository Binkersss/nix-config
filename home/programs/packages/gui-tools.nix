{
  config,
  pkgs,
  zen-browser,
  ...
}: {
  home.packages = with pkgs;
    [
      # Terminal
      ghostty

      # Launcher
      fuzzel

      # Citations
      zotero
      sqlite # for zotero nvim plugin

      # Locker
      swaylock

      # kdePackages.dolphin
      # kdePackages.qtwayland # Required for Dolphin on Wayland
      ranger

      # XWayland support for niri
      xwayland-satellite
    ]
    ++ [
      # Browser (from flake input)
      zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
}
