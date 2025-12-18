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

    initExtra = ''
      # Starship transient prompt
      function set_win_title(){
        echo -ne "\033]0; $(basename "$PWD") \007"
      }
      starship_precmd_user_func="set_win_title"

      # Enable transient prompt
      function zle-line-init() {
        emulate -L zsh
        [[ $CONTEXT == start ]] || return 0

        while true; do
          zle .reset-prompt
          zle -R
          break
        done
      }
      zle -N zle-line-init

      function transient-prompt() {
        echo -n "\e[1;32m❯\e[0m "
      }
    '';
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;

      # Minimal format: NixOS icon, directory name, git info, prompt
      format = "$nix_shell$directory$git_branch$git_status$character";

      # Enable transient prompt
      continuation_prompt = "";

      # NixOS indicator (only show when in nix-shell)
      nix_shell = {
        format = "[ ](bold cyan)";
        disabled = false;
      };

      # Directory - show only current directory name
      directory = {
        format = "[ $path](bold blue)";
        truncation_length = 1;
        truncate_to_repo = false;
        fish_style_pwd_dir_length = 0;
      };

      # Git branch with nerd font icon
      git_branch = {
        format = "[ $branch](bold magenta)";
        symbol = " ";
      };

      # Git status with nerd font icons
      git_status = {
        format = "([$all_status$ahead_behind](bold yellow))";
        staged = " ";
        modified = " ";
        untracked = "?";
        deleted = " ";
        conflicted = "";
        ahead = "⇡$count";
        behind = "⇣$count";
        diverged = "⇕⇡$ahead_count⇣$behind_count";
        stashed = "";
      };

      # Prompt character
      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
        format = " $symbol ";
      };
    };
  };
}
