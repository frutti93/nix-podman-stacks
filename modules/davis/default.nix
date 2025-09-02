{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "davis";
  dbName = "${name}-db";
  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    adminUsername = lib.mkOption {
      type = lib.types.str;
      default = "admin";
      description = ''
        Admin username to access the dashboard.
      '';
    };
    adminPasswordFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the file containing the admin password.
      '';
    };
    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.
        Variables can be either set directly or sourced from a file (e.g. for secrets).

        See <https://github.com/tchapi/davis/blob/main/docker/.env>
      '';
      example = {
        MAIL_PASSWORD = {
          fromFile = "/run/secrets/secret_name";
        };
        MAIL_HOST = "smtp.myprovider.com";
      };
    };
    enableLdapAuth = lib.mkOption {
      type = lib.types.bool;
      default = config.nps.stacks.lldap.enable;
      defaultText = lib.literalExpression ''config.nps.stacks.lldap.enable'';
      description = ''
        Whether to enable login via LLDAP as an auth provider
      '';
    };

    db = {
      type = lib.mkOption {
        type = lib.types.enum [
          "sqlite"
          "postgres"
        ];
        default = "sqlite";
        description = ''
          Type of the database to use.
          Can be set to "sqlite" or "postgres".
          If set to "postgres", the `postgresPasswordFile` option must be set.
        '';
      };
      postgresUser = lib.mkOption {
        type = lib.types.str;
        default = "davis";
        description = ''
          The PostgreSQL user to use for the database.
          Only used if db.type is set to "postgres".
        '';
      };
      postgresPasswordFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          The file containing the PostgreSQL password for the database.
          Only used if db.type is set to "postgres".
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers = {
      ${name} = {
        image = "ghcr.io/tchapi/davis-standalone:5.1.3";
        volumes = lib.optional (cfg.db.type == "sqlite") "${storage}/sqlite:/data";

        extraEnv =
          {
            APP_ENV = "prod";
            CALDAV_ENABLED = true;
            CARDDAV_ENABLED = true;
            WEBDAV_ENABLED = false;
            PUBLIC_CALENDARS_ENABLED = true;
            APP_TIMEZONE = config.nps.defaultTz;
            ADMIN_LOGIN = cfg.adminUsername;
            ADMIN_PASSWORD.fromFile = cfg.adminPasswordFile;
            AUTH_METHOD = "Basic";
            AUTH_REALM = "SabreDAV";
            DATABASE_DRIVER = "sqlite";
            DATABASE_URL = "sqlite:////data/davis-database.db";
          }
          // lib.optionalAttrs cfg.enableLdapAuth (let
            lldap = config.nps.stacks.lldap;
          in {
            AUTH_METHOD = "LDAP";
            LDAP_AUTH_URL = lldap.address;
            LDAP_DN_PATTERN = "uid=%%u,OU=people," + lldap.baseDn;
            LDAP_MAIL_ATTRIBUTE = "mail";
            LDAP_AUTH_USER_AUTOCREATE = true;
            LDAP_CERTIFICATE_CHECKING_STRATEGY = "try";
          })
          // lib.optionalAttrs (cfg.db.type == "postgres") {
            DATABASE_DRIVER = "postgresql";
            DATABASE_URL.fromTemplate = "postgresql://${cfg.db.postgresUser}:{{ file.Read `${cfg.db.postgresPasswordFile}` }}@${dbName}:5432/davis?charset=UTF-8";
          };

        extraConfig.Service.ExecStartPost = [
          (lib.getExe (
            pkgs.writeShellScriptBin "${name}-migrations" ''
              ${lib.getExe config.nps.package} exec ${name} sh -c "APP_ENV=prod bin/console doctrine:migrations:migrate --no-interaction"
            ''
          ))
        ];

        dependsOnContainer = lib.optional (cfg.db.type == "postgres") dbName;
        stack = name;
        port = 9000;
        traefik.name = name;
        homepage = {
          category = "General";
          name = "Davis";
          settings = {
            description = "DAV Server";
            icon = "davis";
          };
        };
      };

      ${dbName} = lib.mkIf (cfg.db.type == "postgres") {
        image = "docker.io/postgres:17";
        volumes = ["${storage}/postgres:/var/lib/postgresql/data"];
        extraEnv = {
          POSTGRES_DB = "davis";
          POSTGRES_USER = cfg.db.postgresUser;
          POSTGRES_PASSWORD.fromFile = cfg.db.postgresPasswordFile;
        };

        extraConfig.Container = {
          Notify = "healthy";
          HealthCmd = "pg_isready -U ${cfg.db.postgresUser} -d davis";
          HealthInterval = "10s";
          HealthTimeout = "10s";
          HealthRetries = 5;
          HealthStartPeriod = "5s";
        };

        stack = name;
      };
    };
  };
}
