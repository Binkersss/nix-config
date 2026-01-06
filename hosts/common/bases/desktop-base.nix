{
  config,
  pkgs,
  ...
}: {
  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable greetd with tuigreet as display manager
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd niri-session";
        user = "greeter";
      };
    };
  };

  # XWayland support
  programs.xwayland.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable Flakes and new nix command line tool
  nix.settings.experimental-features = ["nix-command" "flakes"];

  environment.systemPackages = with pkgs; [
    neovim
    git
    git-crypt
    wget
    curl
    htop
    tmux
    zsh
    fontconfig
    xdg-utils
    i3 # for x11 troubleshooting
    dmenu
  ];

  fonts.fontconfig.enable = true;

  ######################################################
  # Fonts to be installed
  ######################################################
  fonts.packages = with pkgs; [
    # System / text fonts
    fira-code
    jetbrains-mono
    hack-font
    inter
    ibm-plex
    merriweather

    # Icon fonts
    font-awesome
    material-design-icons
    powerline-fonts

    # Nerd Fonts subset (FiraCode, JetBrains Mono, Hack)
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.hack
  ];

  ######################################################
  # Default fonts for applications
  ######################################################
  fonts.fontconfig.defaultFonts = {
    monospace = [
      "Fira Code Nerd Font"
      "JetBrains Mono Nerd Font"
      "Hack Nerd Font"
    ];
    sansSerif = [
      "Inter"
      "IBM Plex Sans"
      "DejaVu Sans"
      "Font Awesome 6 Free Solid"
      "Material Design Icons"
    ];
    serif = [
      "IBM Plex Serif"
      "Merriweather"
      "DejaVu Serif"
    ];
  };

  programs.zsh.enable = true;

  environment.sessionVariables = {
    TERM = "xterm-256color";
  };
}
