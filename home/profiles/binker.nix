{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./base.nix
    ../programs/packages
    ./desktop.nix
  ];

  home.username = "binker";
  home.homeDirectory = "/home/binker";

  programs.ssh = {
    enable = true;

    # Add keys automatically
    extraConfig = ''
      AddKeysToAgent yes
      IdentityFile ~/.ssh/id_ed25519_github
    '';
  };
  services.ssh-agent.enable = true;

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Nathaniel Chappelle";
        email = "nathaniel@chappelle.dev";
      };
      init.defaultBranch = "main";
    };
  };

  home.file.".config/nvim".source = builtins.path {
    path = ../../dotfiles/nvim;
    name = "nvim-config";
  };

  home.file.".config/tmux".source = builtins.path {
    path = ../../dotfiles/tmux;
    name = "tmux-config";
  };

  home.file.".config/ghostty".source = builtins.path {
    path = ../../dotfiles/ghostty;
    name = "ghostty-config";
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -l";
      ff = "fastfetch";
      f = "pay-respects";
    };
    history.size = 10000;
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
      ];
      theme = "robbyrussell";
    };
  };
}
