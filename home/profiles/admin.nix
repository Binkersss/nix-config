{ config, pkgs, ... }:

{
  imports = [ 
    ./base.nix 
  ];

  # Admin-specific packages
  home.packages = with pkgs; [
    tcpdump
    netcat
    nmap
    strace
    lsof
    iotop
    sysstat
    duf
    btop
  ];
}
