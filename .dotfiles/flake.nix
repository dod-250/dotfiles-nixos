{
  description = "dods flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    
    # spicetify-nix
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # NixVim
    nixvim = {
      url = "github:nix-community/nixvim";
    };
  };

  outputs = { self, nixpkgs, home-manager, spicetify-nix, nixvim, ... }:
  let
    lib = nixpkgs.lib;
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    nixosConfigurations = {
      nixos = lib.nixosSystem {
        inherit system;
        modules = [ ./configuration.nix ];
      };
    };
    
    homeConfigurations = {
      dod = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        # Passer spicetify-nix aux modules via extraSpecialArgs
        extraSpecialArgs = { 
          inherit spicetify-nix;
        };
        modules = [ 
          ./home.nix
	  nixvim.homeModules.nixvim
          # Import du module spicetify-nix
          spicetify-nix.homeManagerModules.default
        ];
      };
    };
  };
}