{ config, pkgs, ... }:

{
  imports = [
    ./base.nix
    ../programs/packages
  ];

  home.username = "binker";
  home.homeDirectory = "/home/binker";

  programs.git = {
    enable = true;
    settings = {
      user = {
      	name = "Nathaniel Chappelle";
	      email = "nathaniel@chappelle.dev";
      };
    };
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
        "zsh-autosuggestions"
        "zsh-syntax-highlighting"
        "pay-respects"
      ];
      theme = "robbyrussell";
    };
  };
}
