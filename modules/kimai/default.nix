{
  config,
  lib,
  ...
}: let
  name = "kimai";
  dbName = "${name}-db";

  storage = "${config.tarow.podman.storageBaseDir}/${name}";

  cfg = config.tarow.podman.stacks.${name};
in {
  imports = import ../mkAliases.nix config lib name [name dbName];

  options.tarow.podman.stacks.${name} = {
    enable = lib.mkEnableOption name;

    envFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to env file containing the `ADMINMAIL`, `ADMINPASS` and
        `DATABASE_URL` variables. The `ADMINPASS` should have at least 8 characters for the
        provisioning to succeed.

        The `DATABASE_URL` variable should be in the format `DATABASE_URL=mysql://<<DATABASE_USER>>:<<DATABASE_PASSWORD>>@kimai-db/<<DATABASE_NAME>>?charset=utf8mb4`
        with the variables matching the ones passed in the `db.envFile` option.
      '';
    };
    db.envFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to env file containing the `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD` and
        `MYSQL_ROOT_PASSWORD` variables.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers = {
      ${name} = {
        # renovate: versioning=regex:^(?<compatibility>.*)-(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)$
        image = "docker.io/kimai/kimai2:apache-2.36.1";
        volumes = [
          "${storage}/data:/opt/kimai/var/data"
          "${storage}/plugins:/opt/kimai/var/plugins"
        ];

        environmentFile = [cfg.envFile];

        dependsOnContainer = [dbName];
        stack = name;

        port = 8001;
        traefik.name = name;
        homepage = {
          category = "General";
          name = "Kimai";
          settings = {
            description = "Time Tracker";
            icon = "kimai";
          };
        };
      };

      ${dbName} = {
        image = "docker.io/mysql:9";
        volumes = ["${storage}/db:/var/lib/mysql"];
        environmentFile = [cfg.db.envFile];

        extraConfig.Container = {
          Notify = "healthy";
          HealthCmd = "mysqladmin -p\\$MYSQL_ROOT_PASSWORD ping -h localhost";
          HealthInterval = "10s";
          HealthTimeout = "10s";
          HealthRetries = 5;
          HealthStartPeriod = "20s";
        };

        stack = name;
      };
    };
  };
}
