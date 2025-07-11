{
  config,
  lib,
  ...
}: let
  name = "mealie";
  storage = "${config.tarow.podman.storageBaseDir}/${name}";
  cfg = config.tarow.podman.stacks.${name};
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.tarow.podman.stacks.${name}.enable = lib.mkEnableOption name;

  config = lib.mkIf cfg.enable {
    services.podman.containers = {
      ${name} = {
        image = "ghcr.io/mealie-recipes/mealie:latest";
        volumes = ["${storage}/data:/app/data/"];
        environment = {
          ALLOW_SIGNUP = false;
          PUID = config.tarow.podman.defaultUid;
          PGID = config.tarow.podman.defaultGid;
          BASE_URL = config.services.podman.containers.${name}.traefik.serviceDomain;
          DB_ENGINE = "sqlite";
        };

        port = 9000;
        traefik.name = name;
        homepage = {
          category = "General";
          name = "Mealie";
          settings = {
            description = "Recipe Manager";
            icon = "mealie";
            widget.type = "mealie";
          };
        };
      };
    };
  };
}
