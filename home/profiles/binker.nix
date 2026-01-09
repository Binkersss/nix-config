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

  programs.neovim = {
    enable = true;

    plugins = with pkgs.vimPlugins; [
      (nvim-treesitter.withPlugins (p: [
        p.bash
        p.c
        p.diff
        p.latex
        p.yaml
        p.html
        p.lua
        p.markdown
        p.markdown_inline
        p.query
        p.vim
        p.vimdoc
      ]))
    ];
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

  home.file.".local/share/applications/ranger.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=ranger
    Icon=ranger
    Exec=ghostty -e ranger %U
    Terminal=false
    Categories=System;FileTools;FileManager;
    MimeType=inode/directory;
  '';

  home.file.".config/ranger/rc.conf".text = ''
    set preview_images true
    set preview_images_method kitty
  '';

  home.file.".config/ranger/rifle.conf".text = ''
    # Text files
    ext txt|md|org = nvim -- "$@"
    mime ^text = nvim -- "$@"

    # PDFs
    ext pdf = zathura -- "$@"

    # Images
    mime ^image = imv -- "$@"

    # Videos
    mime ^video = mpv -- "$@"

    # Audio
    mime ^audio = mpv -- "$@"

    # Archives
    ext 7z|ace|ar|arc|bz2?|cab|cpio|cpt|deb|dgc|dmg|gz = file-roller -- "$@"
    ext iso|jar|msi|pkg|rar|shar|tar|tgz|xar|xpi|xz|zip = file-roller -- "$@"

    # Office documents
    ext docx?|xlsx?|pptx? = libreoffice -- "$@"
    ext odt|ods|odp = libreoffice -- "$@"
  '';

  home.file.".local/bin/ranger-wrapper.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash

      echo "=== WRAPPER CALLED ===" >> /tmp/ranger-wrapper-debug.log
      echo "All args: $@" >> /tmp/ranger-wrapper-debug.log

      multiple="$1"
      directory="$2"
      save="$3"
      path="$4"
      out="$5"

      if [ "$directory" = "1" ]; then
          echo "Directory mode" >> /tmp/ranger-wrapper-debug.log
          ${pkgs.ghostty}/bin/ghostty --class=file_chooser -e sh -c "${pkgs.ranger}/bin/ranger --choosedir='$out' '$path'" 2>> /tmp/ranger-wrapper-debug.log
      else
          echo "File mode" >> /tmp/ranger-wrapper-debug.log
          ${pkgs.ghostty}/bin/ghostty --class=file_chooser -e sh -c "${pkgs.ranger}/bin/ranger --choosefile='$out' '$path'" 2>> /tmp/ranger-wrapper-debug.log
      fi

      echo "Exit code: $?" >> /tmp/ranger-wrapper-debug.log
      if [ -f "$out" ]; then
          echo "Output file contents: $(cat '$out')" >> /tmp/ranger-wrapper-debug.log
      else
          echo "No output file created" >> /tmp/ranger-wrapper-debug.log
      fi
    '';
  };

  # xdg.configFile."xdg-desktop-portal-termfilechooser/config" = {
  #   force = true;
  #   text = ''
  #     [filechooser]
  #     cmd=ranger-wrapper.sh
  #     default_dir=$HOME
  #     open_mode=suggested
  #     save_mode=suggested
  #   '';
  # };

  # xdg.mimeApps = {
  #   enable = true;
  #   defaultApplications = {
  #     "inode/directory" = "ranger.desktop";
  #     "x-scheme-handler/file" = "ranger.desktop";
  #   };
  # };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ls = "eza";
      ll = "eza -l";
      tree = "eza -T";
      ff = "fastfetch";
      f = "pay-respects";
    };
    history.size = 10000;

    initContent = ''
      # Auto-start tmux (but prevent nesting)
       if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
           tmux attach -t default || tmux new -s default
       fi

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

       # Word navigation with Ctrl+Arrow keys
       bindkey "^[[1;5C" forward-word      # Ctrl+Right
       bindkey "^[[1;5D" backward-word     # Ctrl+Left
    '';
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;

      format = "(bol cyan) $directory$git_branch$git_status$character";
      right_format = "$time";

      continuation_prompt = "";

      directory = {
        format = "[ $path](bold blue)";
        truncation_length = 1;
        truncate_to_repo = false;
        fish_style_pwd_dir_length = 0;
        read_only = " 󰌾";
        style = "blue";
      };

      # Git branch with nerd font icon
      git_branch = {
        format = "[ $branch](bold magenta)";
        symbol = " ";
        style = "bright-black";
      };

      # Git status with nerd font icons
      git_status = {
        format = "( [$all_status$ahead_behind](bold yellow))";
        style = "cyan";
        staged = "";
        modified = "";
        untracked = "";
        deleted = "";
        renamed = "";
        conflicted = "";
        ahead = "⇡$count";
        behind = "⇣$count";
        diverged = "⇕⇡$ahead_count⇣$behind_count";
        stashed = "≡";
      };

      # Git state
      git_state = {
        format = "( [$state( $progress_current/$progress_total)]($style)) ";
        style = "bright-black";
      };

      time = {
        disabled = false;
        format = " [$time](bold dimmed white)";
        time_format = "%T";
      };

      cmd_duration = {
        format = "[$duration]($style) ";
        style = "yellow";
      };

      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
        format = " $symbol ";
      };
    };
  };
}
