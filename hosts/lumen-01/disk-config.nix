{ ... }:

{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/sda";  # adjust for your machine
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02";  # BIOS Boot
            };

            ESP = {
              size = "512M";
              type = "EF00";  # EFI System Partition
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };

            root = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot";
                settings = {
                  allowDiscards = true;
                  # keyFile = "/path" (if using one)
                };
                content = {
                  type = "btrfs";
                  subvolumes = {
                    "@root" = {
                      mountpoint = "/";
                    };
                    "@home" = {
                      mountpoint = "/home";
                    };
                    "@nix" = {
                      mountpoint = "/nix";
                    };
                    "@log" = {
                      mountpoint = "/var/log";
                    };
                    "@cache" = {
                      mountpoint = "/var/cache";
                    };
                    "@snapshots" = {
                      mountpoint = "/.snapshots";
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}

