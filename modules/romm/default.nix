{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  name = "romm";
  dbName = "${name}-db";

  storage = "${config.tarow.podman.storageBaseDir}/${name}";
  cfg = config.tarow.podman.stacks.${name};

  yaml = pkgs.formats.yaml {};
in {
  imports = import ../mkAliases.nix config lib name [name dbName];

  options.tarow.podman.stacks.${name} = {
    enable = lib.mkEnableOption name;
    setupAdminUser = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to enable automated admin user provisioning.
        If enabled, an admin user will be created automatically on startup.

        Make sure the env file contains the `envFile` option contains the variables `ADMIN_USERNAME` (default 'admin'),
        `ADMIN_PASSWORD` (default 'admin') and `ADMIN_EMAIL` (default 'admin@admin.com').

        When disabled, you will be prompted for admin user creation when visiting the RomM UI the first time.
      '';
    };
    settings = lib.mkOption {
      type = lib.types.nullOr yaml.type;
      default = null;
      apply = settings:
        if settings != null
        then yaml.generate "config.yml" settings
        else null;
      example = {
        platforms = {
          gc = "ngc";
          psx = "ps";
        };
      };
      description = ''
        RomM settings. If set, will be mounted as the `config.yml`.
        If unset, configuration through UI is possible.

        See <https://docs.romm.app/latest/Getting-Started/Configuration-File/>
      '';
    };
    env = lib.mkOption {
      type = (options.services.podman.containers.type.getSubOptions []).environment.type;
      default = {};
      description = ''
        Additional environment variables passed to the RomM container

        See <https://docs.romm.app/latest/Getting-Started/Environment-Variables/>
      '';
    };
    envFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to env file containing the `DB_PASSWD` and the `ROMM_AUTH_SECRET_KEY` variables.
        The `DB_PASSWD` should match the `MARIA_DB` password passed in the `db.envFile` option.

        Can optionally include more secrets and other variables, such as API_KEYS, e.g.
        `RETROACHIEVEMENTS_API_KEY` or `STEAMGRIDDB_API_KEY`.

        See <https://docs.romm.app/latest/Getting-Started/Environment-Variables/>
      '';
    };
    db.envFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the env file containing the 'MARIADB_ROOT_PASSWORD' and 'MARIADB_PASSWORD' variables.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers = {
      ${name} = {
        image = "ghcr.io/rommapp/romm:latest";
        volumes =
          [
            "${storage}/resources:/romm/resources"
            "${storage}/redis_data:/redis-data"
            "${storage}/library:/romm/library"
            "${storage}/assets:/romm/assets"
          ]
          ++ [
            (
              if (cfg.settings == null)
              then "${storage}/config:/romm/config"
              else "${cfg.settings}:/romm/config/config.yml"
            )
          ];

        environmentFile = [cfg.envFile];
        environment = let
          db = cfg.containers.${dbName}.environment;
        in
          {
            DB_HOST = dbName;
            DB_NAME = db.MARIADB_DATABASE;
            DB_USER = db.MARIADB_USER;
          }
          // cfg.env;

        extraConfig = {
          Container = {
            Notify = "healthy";
            HealthCmd = "curl -s -f http://localhost:8080/api/heartbeat || exit 1";
            HealthInterval = "10s";
            HealthTimeout = "10s";
            HealthRetries = 5;
            HealthStartPeriod = "5s";
          };
          Service = {
            ExecStartPost = lib.mkIf cfg.setupAdminUser (lib.getExe (
              pkgs.writeShellScriptBin "user_provision" ''
                ${lib.getExe pkgs.podman} exec ${name} bash -c "$(${pkgs.coreutils}/bin/cat ${./create_admin_user.sh})"
              ''
            ));
          };
        };

        dependsOnContainer = [dbName];
        stack = name;

        port = 8080;
        traefik.name = name;
        homepage = {
          category = "General";
          name = "RomM";
          settings = {
            description = "Rom Manager";
            icon = "romm";
            widget.type = "romm";
          };
        };
      };
      ${dbName} = {
        image = "docker.io/mariadb:11";
        volumes = ["${storage}/db:/var/lib/mysql"];
        environment = {
          MARIADB_DATABASE = "romm";
          MARIADB_USER = "romm-user";
        };
        environmentFile = [cfg.db.envFile];

        extraConfig.Container = {
          Notify = "healthy";
          HealthCmd = "healthcheck.sh --connect --innodb_initialized";
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
