{
  config,
  lib,
  ...
}: let
  name = "mazanoke";
  cfg = config.nps.stacks.${name};
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name}.enable = lib.mkEnableOption name;

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "ghcr.io/civilblur/mazanoke:v1.1.5";

      port = 80;
      traefik.name = name;
      homepage = {
        category = "General";
        name = "Mazanoke";
        settings = {
          description = "Image Optimizer";
          icon = "mazanoke";
        };
      };
    };
  };
}
