{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    fastfetch
    nnn
    pay-respects

    # archives
    zip
    xz
    unzip
    p7zip
    zstd
    
    # utils
    ripgrep
    jq
    yq-go
    eza
    fzf
    
    # misc
    cowsay
    file
    which
    tree
    gnused
    gnutar
    gawk
    gnupg
    
    # nix related
    nix-output-monitor
    
    # productivity
    hugo
    glow
  ];
}
