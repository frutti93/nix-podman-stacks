{
  config,
  lib,
  ...
}: let
  name = "docker-socket-proxy";
  cfg = config.tarow.podman.stacks.${name};
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.tarow.podman.stacks.${name}.enable = lib.mkEnableOption name;

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "ghcr.io/tecnativa/docker-socket-proxy:latest";

      volumes = [
        "${config.tarow.podman.socketLocation}:/var/run/docker.sock:ro"
      ];

      environment = {
        CONTAINERS = 1;
        SERVICES = 1;
        TASKS = 1;
        POST = 0;
      };

      port = 2375;
      traefik.name = "dsp";
      homepage = {
        category = "Network & Administration";
        name = "Docker Socket Proxy";
        settings = {
          href = null;
          description = "Security Proxy for the Docker Socket";
          icon = "haproxy";
        };
      };
    };
  };
}
