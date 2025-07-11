{
  config,
  lib,
  ...
}: let
  name = "stirling-pdf";
  cfg = config.tarow.podman.stacks.${name};
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.tarow.podman.stacks.${name}.enable = lib.mkEnableOption name;

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "docker.io/frooodle/s-pdf:latest";
      environment = {
        DOCKER_ENABLE_SECURITY = "false";
      };

      port = 8080;
      traefik.name = "pdf";
      homepage = {
        category = "General";
        name = "Stirling PDF";
        settings = {
          description = "Web-based PDF-Tools";
          icon = "stirling-pdf";
        };
      };
    };
  };
}
