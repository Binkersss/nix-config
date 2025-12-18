{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Language runtimes & compilers
    go
    rustc
    cargo
    clang
    
    # Language Servers
    lua-language-server
    nodePackages.typescript-language-server
    pyright
    svelte-language-server
    gopls
    clang-tools
    nil
    vscode-langservers-extracted
    zls
    marksman

    # Formatters
    stylua
    alejandra

    # JS FUCKING SUCKK
    bun 

    # Python
    python3
    
    # Build tools
    cmake
    gnumake
    pkg-config
    
    # Version control
    git-lfs
    gh  # GitHub CLI
    
    # Container tools
    docker-compose
    kubectl
    
    # Development utilities
    direnv
    just  # command runner
  ];
}
