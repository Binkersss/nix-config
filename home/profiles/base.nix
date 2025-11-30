{ config, pkgs, ... }:

{
  home.stateVersion = "24.05";

  # Shared packages for all users
  home.packages = with pkgs; [
    htop
    tree
    curl
    wget
    jq
    ripgrep
    fd
    ncdu
  ];

  # Basic shell configuration
  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "ls -lah";
      ".." = "cd ..";
      "..." = "cd ../..";
    };
  };

  # Basic git config (users can override)
  programs.git = {
    enable = true;
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };
}
