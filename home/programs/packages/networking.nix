{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    mtr
    iperf3
    dnsutils
    ldns
    aria2
    socat
    nmap
    ipcalc
  ];
}
