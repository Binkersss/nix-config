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

      spotify-player

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
      zathura # PDF viewer
      imv # Image viewer (lightweight)
      mpv # Video/audio player
      file-roller # Archive manager (or: ark, xarchiver)
      xdg-desktop-portal-termfilechooser

      # Optional but useful:
      ffmpegthumbnailer # Video thumbnails in ranger
      poppler-utils # PDF thumbnails/preview
      highlight # Syntax highlighting for previews
      mediainfo # Media file info

      # XWayland support for niri
      xwayland-satellite
    ]
    ++ [
      # Browser (from flake input)
      zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
}
