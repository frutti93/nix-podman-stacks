{
  config,
  lib,
  ...
}:
let
  name = "karakeep";
  chromeName = "${name}-chrome";
  meilisearchName = "${name}-meilisearch";

  storage = "${config.nps.storageBaseDir}/${name}";

  cfg = config.nps.stacks.${name};
in
{
  imports = import ../mkAliases.nix config lib name [
    name
    chromeName
    meilisearchName
  ];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    nextauthSecretFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to file containing the NEXTAUTH_SECRET

        See <https://docs.karakeep.app/configuration/>
      '';
    };
    meiliMasterKeyFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to file containing the MEILI_MASTER_KEY

        See <https://docs.karakeep.app/configuration/>
      '';
    };
    authelia = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable OIDC login with Authelia. This will register an OIDC client in Authelia
          and setup the necessary configuration.

          For details, see:

          - <https://www.authelia.com/integration/openid-connect/clients/karakeep/>
          - <https://docs.karakeep.app/configuration/#authentication--signup>
        '';
      };
      clientSecretFile = lib.mkOption {
        type = lib.types.str;
        description = ''
          The file containing the client secret for the OIDC client that will be registered in Authelia.
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
    };
  };

  config = lib.mkIf cfg.enable {

    nps.stacks.authelia = lib.mkIf cfg.authelia.enable {
      oidc.clients.${name} = {
        client_name = "Karakeep";
        client_secret = cfg.authelia.clientSecretHash;
        public = false;
        authorization_policy = "one_factor";
        claims_policy = "romm";
        require_pkce = false;
        pkce_challenge_method = "";
        pre_configured_consent_duration = "1 month";
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceDomain}/api/auth/callback/custom"
        ];
      };

      # See <https://www.authelia.com/integration/openid-connect/openid-connect-1.0-claims/#restore-functionality-prior-to-claims-parameter>
      settings.identity_providers.oidc.claims_policies.${name}.id_token = [
        "email"
        "email_verified"
        "alt_emails"
        "preferred_username"
        "name"
      ];
    };

    services.podman.containers = {
      ${name} = {
        image = "ghcr.io/karakeep-app/karakeep:0.26.0";
        volumes = [
          "${storage}/data:/data"
        ];
        environment = {
          DATA_DIR = "/data";
          MEILI_ADDR = "http://${meilisearchName}:7700";
          BROWSER_WEB_URL = "http://${chromeName}:9222";
          NEXTAUTH_URL = cfg.containers.${name}.traefik.serviceDomain;
        };
        extraEnv = {
          NEXTAUTH_SECRET.fromFile = cfg.nextauthSecretFile;
          MEILI_MASTER_KEY.fromFile = cfg.meiliMasterKeyFile;
        }
        // lib.optionalAttrs cfg.authelia.enable {
          OAUTH_WELLKNOWN_URL = "${config.nps.containers.authelia.traefik.serviceDomain}/.well-known/openid-configuration";
          OAUTH_CLIENT_ID = name;
          OAUTH_CLIENT_SECRET.fromFile = cfg.authelia.clientSecretFile;
          OAUTH_PROVIDER_NAME = "Authelia";
        };

        stack = name;
        port = 3000;
        traefik.name = name;
        homepage = {
          category = "General";
          name = "Karakeep";
          settings = {
            description = "Bookmark Everything";
            icon = "karakeep";
            widget.type = "karakeep";
          };
        };
      };

      ${chromeName} = {
        image = "gcr.io/zenika-hub/alpine-chrome:124";
        exec = lib.concatStringsSep " " [
          "--no-sandbox"
          "--disable-gpu"
          "--disable-dev-shm-usage"
          "--remote-debugging-address=0.0.0.0"
          "--remote-debugging-port=9222"
          "--hide-scrollbars"
        ];

        stack = name;
      };

      ${meilisearchName} = {
        image = "docker.io/getmeili/meilisearch:v1.15.2";
        environment = {
          MEILI_NO_ANALYTICS = "true";
        };
        extraEnv = {
          MEILI_MASTER_KEY.fromFile = cfg.meiliMasterKeyFile;
        };
        volumes = [ "${storage}/meilisearch:/meili_data" ];

        stack = name;
      };
    };
  };
}
