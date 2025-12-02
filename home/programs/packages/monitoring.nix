{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    btop
    iotop
    iftop
    
    # system call monitoring
    strace
    ltrace
    lsof
    
    # system tools
    sysstat
    lm_sensors
    ethtool
    pciutils
    usbutils
  ];
}
