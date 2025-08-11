{
  config,
  lib,
  ...
}: let
  name = "healthchecks";

  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    envFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the environment file for Healthchecks.
        Should contain SECRET_KEY, SUPERUSER_EMAIL and SUPERUSER_PASSWORD envionment variables
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers = {
      ${name} = {
        # renovate: versioning=regex:^v(?<major>\d+)\.(?<minor>\d+)-ls(?<build>.+)$
        image = "ghcr.io/linuxserver/healthchecks:v3.10-ls305";
        volumes = ["${storage}/config:/config"];
        environment = {
          PUID = config.nps.defaultUid;
          PGID = config.nps.defaultGid;
          SITE_ROOT = config.services.podman.containers.${name}.traefik.serviceDomain;
          SITE_NAME = "Healthchecks";
          REGISTRATION_OPEN = "False";
          INTEGRATIONS_ALLOW_PRIVATE_IPS = "True";
          APPRISE_ENABLED = "True";
          DEBUG = "False";
        };

        environmentFile = [cfg.envFile];
        port = 8000;

        stack = name;
        traefik.name = name;
        homepage = {
          category = "Monitoring";
          name = "Healthchecks";
          settings = {
            description = "Job Monitoring";
            icon = "healthchecks";
            widget.type = "healthchecks";
          };
        };
      };
    };
  };
}
