{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    fastfetch
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
    gnused
    gnutar
    gawk
    hugo

    # nix related
    nix-output-monitor
  ];
}
