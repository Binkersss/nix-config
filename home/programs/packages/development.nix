{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Language runtimes & compilers
    gopls
    rustc
    cargo
    clang-tools
    
    # Language Servers
    lua-language-server
    nodePackages.typescript-language-server
    pyright
    svelte-language-server

    # Formatters
    stylua

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
