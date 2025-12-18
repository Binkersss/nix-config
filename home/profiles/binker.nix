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
      # Compact Zsh Theme with Git Integration and Transient Prompt

      autoload -Uz vcs_info
      precmd_vcs_info() { vcs_info }
      precmd_functions+=( precmd_vcs_info )
      setopt prompt_subst

      # Git status configuration with Nerd Font icons
      zstyle ':vcs_info:*' enable git
      zstyle ':vcs_info:*' check-for-changes true
      zstyle ':vcs_info:*' stagedstr '%F{green}%f'
      zstyle ':vcs_info:*' unstagedstr '%F{yellow}%f'
      zstyle ':vcs_info:git:*' formats ' %F{cyan}%f %F{magenta}%b%f %u%c'
      zstyle ':vcs_info:git:*' actionformats ' %F{cyan}%f %F{magenta}%b%f %F{red}%a%f %u%c'

      # Main prompt with OS icon, directory name only, and git info
      PROMPT='%F{cyan}%f\uf313 %F{blue}%1~%f$vcs_info_msg_0_ %F{green}❯%f '

      # Transient prompt implementation
      zle-line-init() {
        emulate -L zsh
        [[ $CONTEXT == start ]] || return 0

        # Print transient prompt for previous command
        () {
          local prompt_height=$(( ''${#PROMPT//\%\{*\%\}/} ))
          print -rn -- $terminfo[el]
        }
      }

      zle -N zle-line-init

      # Store original prompt
      _original_prompt=$PROMPT

      # Before command execution, simplify previous prompts
      add-zsh-hook preexec _transient_prompt
      function _transient_prompt() {
        print -rn -- "\r\033[K%F{green}❯%f "
      }
    '';

    # Restore key bindings for word navigation
    initExtraBeforeCompInit = ''
      bindkey "^[[1;5C" forward-word
      bindkey "^[[1;5D" backward-word
    '';
  };
}
