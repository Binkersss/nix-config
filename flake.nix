{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, home-manager, zen-browser, noctalia, niri, ... }:
      { nixosConfigurations.lumen-01 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/lumen-01/configuration.nix
          ./hosts/lumen-01/hardware-configuration.nix

          ./hosts/common/bases/server-base.nix
          ./hosts/common/users/binker.nix

	  ./modules/homelab

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.binker = ./home/profiles/binker.nix;

	    # Optionally, use home-manager.extraSpecialArgs to pass
            # arguments to home.nix
          }
        ];
      };
      
      nixosConfigurations.spectra = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/spectra/configuration.nix
          ./hosts/spectra/hardware-configuration.nix

          ./hosts/common/bases/desktop-base.nix
          ./hosts/common/users/binker.nix

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.binker = ./home/profiles/binker.nix;
            home-manager.extraSpecialArgs = { 
	      inherit zen-browser noctalia niri;
	    };

	    # Optionally, use home-manager.extraSpecialArgs to pass
            # arguments to home.nix
          }
        ];
      };
    };
}
