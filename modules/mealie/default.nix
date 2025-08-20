{
  config,
  lib,
  ...
}:
let
  name = "mealie";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};
in
{
  imports = import ../mkAliases.nix config lib name [ name ];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
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
    nps.stacks.lldap.bootstrap.groups =
      let
        env = cfg.containers.${name}.environment;
      in
      lib.mkIf cfg.authelia.enable {
        mealie-admins = lib.mkIf (builtins.hasAttr "OIDC_ADMIN_GROUP" env) {
          name = env.OIDC_ADMIN_GROUP;
        };
        mealie-users = lib.mkIf (builtins.hasAttr "OIDC_USER_GROUP" env) {
          name = env.OIDC_USER_GROUP;
        };
      };
    nps.stacks.authelia = lib.mkIf cfg.authelia.enable {
      oidc.clients.${name} = {
        client_name = "Mealie";
        client_secret = cfg.authelia.clientSecretHash;
        public = false;
        authorization_policy = "one_factor";
        require_pkce = false;
        pkce_challenge_method = "";
        pre_configured_consent_duration = "1 month";
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceDomain}/login"
        ];
      };
    };

    services.podman.containers = {
      ${name} = {
        image = "ghcr.io/mealie-recipes/mealie:v3.1.1";
        volumes = [ "${storage}/data:/app/data/" ];
        environment = {
          ALLOW_SIGNUP = false;
          PUID = config.nps.defaultUid;
          PGID = config.nps.defaultGid;
          BASE_URL = config.services.podman.containers.${name}.traefik.serviceDomain;
          DB_ENGINE = "sqlite";
          #ALLOW_PASSWORD_LOGIN = false;
        };

        extraEnv = lib.optionalAttrs cfg.authelia.enable {
          OIDC_AUTH_ENABLED = true;
          OIDC_PROVIDER_NAME = "Authelia";
          OIDC_SIGNUP_ENABLED = true;
          OIDC_CONFIGURATION_URL = "${config.nps.containers.authelia.traefik.serviceDomain}/.well-known/openid-configuration";
          OIDC_CLIENT_ID = name;
          OIDC_CLIENT_SECRET.fromFile = cfg.authelia.clientSecretFile;
          OIDC_AUTO_REDIRECT = false;
          OIDC_ADMIN_GROUP = "mealie-admins";
          OIDC_USER_GROUP = "mealie-users";
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
