{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "gatus";
  dbName = "${name}-db";
  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";
  yaml = pkgs.formats.yaml {};
in {
  imports = import ../mkAliases.nix config lib name [
    name
    dbName
  ];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    jwtSecretFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the file containing the JWT secret.

        See <https://vikunja.io/docs/config-options/#1-service-JWTSecret>
      '';
    };
    settings = lib.mkOptipn {
      type = yaml.type;
      default = {};
      description = ''
        Extra settings being provided as the `/etc/vikunja/config.yml` file.

        See <https://vikunja.io/docs/config-options>
      '';
    };
    oidc = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable OIDC login with Authelia. This will register an OIDC client in Authelia
          and setup the necessary configuration.

          For details, see:

          - <https://www.authelia.com/integration/openid-connect/clients/gatus/>
          - <https://github.com/TwiN/gatus?tab=readme-ov-file#oidc>
        '';
      };
      clientSecretFile = lib.mkOption {
        type = lib.types.str;
        description = ''
          The file containing the client secret for the Gatus OIDC client that will be registered in Authelia.
        '';
      };
      clientSecretHash = lib.mkOption {
        type = lib.types.str;
        description = ''
          The hashed client_secret. Will be set in the Authelia client config.
          For examples on how to generate a client secret, see

          <https://www.authelia.com/integration/openid-connect/frequently-asked-questions/#client-secret>
        '';
      };
      userGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_user";
        description = "Users of this group will be able to log in";
      };
    };

    db = {
      type = lib.mkOption {
        type = lib.types.enum [
          "sqlite"
          "postgres"
        ];
        description = ''
          Type of the database to use.
          Can be set to "sqlite" or "postgres".
          If set to "postgres", the `postgresPasswordFile` option must be set.
        '';
      };
      postgresUser = lib.mkOption {
        type = lib.types.str;
        default = "gatus";
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
    nps.stacks.lldap.bootstrap.groups = lib.mkIf cfg.oidc.enable {
      ${cfg.oidc.userGroup} = {};
    };
    nps.stacks.authelia = lib.mkIf cfg.oidc.enable {
      oidc.clients.${name} = {
        client_name = "Gatus";
        client_secret = cfg.oidc.clientSecretHash;
        public = false;
        authorization_policy = name;
        require_pkce = false;
        pkce_challenge_method = "";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceUrl}/authorization-code/callback"
        ];
      };

      # No real RBAC control based on custom claims / groups yet. Restrict user-access on Authelia level for now
      # See <https://github.com/TwiN/gatus/issues/638>
      settings.identity_providers.oidc.authorization_policies.${name} = {
        default_policy = "deny";
        rules = [
          {
            policy = config.nps.stacks.authelia.defaultAllowPolicy;
            subject = "group:${cfg.oidc.userGroup}";
          }
        ];
      };
    };

    services.podman.containers = {
      ${name} = let
        settings =
          cfg.settings
          // {
            endpoints = lib.map (e: lib.recursiveUpdate cfg.defaultEndpoint e) (cfg.settings.endpoints or []);
          };
        configDir = "/app/config";
      in {
        image = "ghcr.io/twin/gatus:v5.23.2";
        volumes =
          [
            "${yaml.generate "config.yml" settings}:${configDir}/config.yml"
          ]
          ++ (lib.map (f: "${f}:${configDir}/${builtins.baseNameOf f}") cfg.extraSettingsFiles)
          ++ lib.optional (cfg.db.type == "sqlite") "${storage}/sqlite:/data";
        
        extraEnv = {
          VIKUNJA_SERVICE_JWTSECRET
        };

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
        extraEnv = {
          POSTGRES_DB = "gatus";
          POSTGRES_USER = cfg.db.postgresUser;
          POSTGRES_PASSWORD.fromFile = cfg.db.postgresPasswordFile;
        };

        stack = name;
      };
    };
  };
}
