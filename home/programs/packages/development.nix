{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Language runtimes & compilers
    go
    rustc
    cargo
    gcc
    clang
    
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
