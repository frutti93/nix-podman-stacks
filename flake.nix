{
  description = "Collection of opinionated rootless Podman stacks";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    sops-nix,
  }: {
    homeModules = import ./modules/module_list.nix;
    templates.default = {
      description = "Nix Podman Stacks Starter";
      path = ./template;
    };
    homeConfigurations.ci = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages."x86_64-linux";
      modules = [
        sops-nix.homeManagerModules.sops
        self.homeModules.all
        {
          home.stateVersion = "25.05";
          home.username = "ci";
          home.homeDirectory = "/home/ci";
        }
        ./template/sops.nix
        ./template/stacks.nix
        {
          sops.defaultSopsFile = nixpkgs.lib.mkForce ./template/secrets.yaml.example;
        }
      ];
    };
  };
}
