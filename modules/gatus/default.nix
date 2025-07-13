{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "gatus";
  dbName = "${name}-db";
  cfg = config.tarow.podman.stacks.${name};
  storage = "${config.tarow.podman.storageBaseDir}/${name}";
  yaml = pkgs.formats.yaml {};
in {
  imports = [./extension.nix] ++ import ../mkAliases.nix config lib name [name dbName];

  options.tarow.podman.stacks.${name} = {
    enable = lib.mkEnableOption name;
    settings = lib.mkOption {
      type = yaml.type;
      description = ''
        Settings for the Gatus container.
        Will be converted to YAML and passed to the container.
        To see all valid settings, refer to the projects documentation: https://github.com/TwiN/gatus
      '';
    };
    extraSettingsFiles = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [];
      description = ''
        List of additional YAML files to include in the settings.
        These files will be mounted as is. Can be used to directly provide YAML files containing secrets,
        e.g. from sops
      '';
    };
    defaultEndpoint = lib.mkOption {
      type = yaml.type;
      default = {
        group = "core";
        interval = "5m";
        client = {
          insecure = true;
          timeout = "10s";
        };
        conditions = [
          "[STATUS] >= 200"
          "[STATUS] < 300"
        ];
      };
      description = ''
        Default endpoint settings. Will merged with each provided endpoint.
        Only applies if endpoint does not override the default endpoint settings.
      '';
    };
    envFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to the environment file for the container.
        Can be used to e.g. pass secrets that are referenced in the settings.
      '';
    };
    db = {
      type = lib.mkOption {
        type = lib.types.enum ["sqlite" "postgres"];
        description = ''
          Type of the database to use.
          Can be set to "sqlite" or "postgres".
          If set to "postgres", the envFile option must be set.
        '';
      };
      envFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          Path to the environment file for the database.
          Required if db.type is set to "postgres".
          Must contain the environment variables 'POSTGRES_USER', and 'POSTGRES_PASSWORD'.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    tarow.podman.stacks.${name}.settings = {
      storage = {
        type = cfg.db.type;
        path =
          if (cfg.db.type == "sqlite")
          then "/data/data.db"
          else "postgres://\${POSTGRES_USER}:\${POSTGRES_PASSWORD}@${dbName}:5432/${cfg.containers.${dbName}.environment.POSTGRES_DB}?sslmode=disable";
      };
    };

    services.podman.containers = {
      ${name} = let
        settings = cfg.settings // {endpoints = lib.map (e: lib.recursiveUpdate cfg.defaultEndpoint e) (cfg.settings.endpoints or []);};
        configDir = "/app/config";
      in {
        image = "ghcr.io/twin/gatus:latest";
        volumes = let
        in
          ["${yaml.generate "config.yml" settings}:${configDir}/config.yml"]
          ++ (lib.map (f: "${f}:${configDir}/${builtins.baseNameOf f}") cfg.extraSettingsFiles)
          ++ lib.optional (cfg.db.type == "sqlite") "${storage}/sqlite:/data";
        environment = {
          GATUS_CONFIG_PATH = configDir;
        };
        environmentFile = (lib.optional (cfg.envFile != null) cfg.envFile) ++ (lib.optional (cfg.db.type == "postgres") cfg.db.envFile);

        stack = name;
        port = 8080;
        traefik.name = name;
        homepage = {
          category = "Monitoring";
          name = "Gatus";
          settings = {
            description = "Health Monitoring";
            icon = "gatus";
            widget.type = "gatus";
          };
        };
      };

      ${dbName} = lib.mkIf (cfg.db.type == "postgres") {
        image = "docker.io/postgres:17";
        volumes = ["${storage}/postgres:/var/lib/postgresql/data"];
        environment = {
          POSTGRES_DB = "gatus";
        };
        environmentFile = [cfg.db.envFile];

        stack = name;
      };
    };
  };
}
