{ config, pkgs, ... }:

{
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

  home.file.".config/nvim".source = ./dotfiles/nvim;
  home.file.".config/tmux".source = ./dotfiles/tmux;

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
