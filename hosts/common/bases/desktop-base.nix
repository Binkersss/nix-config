{ config, pkgs, ... }:


{ 
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
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [
    neovim
    git
    wget
    curl
    htop
    tmux
    zsh

    fontconfig
    # Text fonts
    fira-code
    jetbrains-mono
    inter
    ibm-plex
    merriweather

    # Icon fonts
    nerd-fonts-fira-code
    nerd-fonts-jetbrains-mono
    nerd-fonts-hack
    font-awesome
    material-design-icons-font
    powerline-fonts
  ];
	
  
  ######################################################
  # Font configuration
  ######################################################
  fonts.fontconfig.enable = true;

  # Default fonts for each generic family
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

  ######################################################
  # Optional: Ensure fonts are available for GTK/QT apps
  ######################################################
  fonts.fonts = with pkgs; [
    fira-code
    fira-code-nerd-font
    jetbrains-mono
    jetbrains-mono-nerd-font
    hack
    inter
    ibm-plex
    merriweather
    font-awesome
    material-design-icons-font
    powerline-fonts
  ];

  ######################################################
  # Optional: fallback rules for missing icons/glyphs
  ######################################################
  fonts.fontconfig.extraConfig = ''
    # fallback for Nerd Fonts
    <match target="pattern">
      <test name="family" compare="eq">
        <string>monospace</string>
      </test>
      <edit name="family" mode="prepend" binding="string">Fira Code Nerd Font</edit>
    </match>

    # fallback for Font Awesome
    <match target="pattern">
      <test name="family" compare="eq">
        <string>sans-serif</string>
      </test>
      <edit name="family" mode="prepend" binding="string">Font Awesome 6 Free Solid</edit>
      <edit name="family" mode="prepend" binding="string">Material Design Icons</edit>
    </match>
  '';

  programs.zsh.enable = true;

  environment.sessionVariables = {
    TERM = "xterm-256color";
  };
}
