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
    ...
  } @ inputs: let
    forAllSystems = nixpkgs.lib.genAttrs [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
  in {
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

    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      docs-json = let
        opts =
          import ./docs/default.nix
          {
            inherit self pkgs inputs system;
          }.optionsJSON;
      in
        pkgs.runCommand "options.json" {inherit opts;} ''
          “cp $opts/share/doc/nixos/options.json $out”
        '';
    });
  };
}
