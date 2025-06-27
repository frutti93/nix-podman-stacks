{
  description = "Collection of opinionated rootless Podman stacks";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
  };

  outputs = {
    self,
    nixpkgs,
  }: {
    homeModules = import ./modules/module_list.nix;
    templates.default = {
      description = "Nix Podman Stacks Starter";
      path = ./template;
    };
  };
}
