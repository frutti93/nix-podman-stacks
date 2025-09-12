{
  config,
  lib,
  ...
}: let
  name = "storyteller";
  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    secretKeyFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the file containing the secret key.

        See <https://storyteller-platform.gitlab.io/storyteller/docs/intro/getting-started#secrets>
      '';
    };
    oidc = {
      registerClient = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to register a OIDC client in Authelia.
          If enabled you need to provide a hashed secret in the `client_secret` option.

          To complete the OIDC setup, you will have to enable it in the Web UI.

          For details, see:
          - <https://storyteller-platform.gitlab.io/storyteller/docs/administering#oauthoidc-configuration>
        '';
      };
      clientSecretHash = lib.mkOption {
        type = lib.types.str;
        description = ''
          The hashed client_secret.
          For examples on how to generate a client secret, see

          <https://www.authelia.com/integration/openid-connect/frequently-asked-questions/#client-secret>
        '';
      };
      userGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_user";
        description = ''
          Users of this group will be able to log in
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.lldap.bootstrap.groups = lib.mkIf cfg.oidc.registerClient {
      ${cfg.oidc.userGroup} = {};
    };
    nps.stacks.authelia = lib.mkIf cfg.oidc.registerClient {
      oidc.clients.${name} = {
        client_name = "Storyteller";
        client_secret = cfg.oidc.clientSecretHash;
        public = false;
        authorization_policy = name;
        require_pkce = true;
        pkce_challenge_method = "S256";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceUrl}/api/v2/auth/callback/authelia"
        ];
      };
      # No real RBAC control based on custom claims / groups yet. Restrict user-access on Authelia level
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

    services.podman.containers.${name} = {
      image = "registry.gitlab.com/storyteller-platform/storyteller:web-v2.2.2";
      volumes = ["${storage}:/data"];

      environment.AUTH_URL = lib.mkIf cfg.oidc.registerClient "${cfg.containers.${name}.traefik.serviceUrl}/api/v2/auth";

      fileEnvMount.STORYTELLER_SECRET_KEY_FILE = cfg.secretKeyFile;

      extraConfig.Container = {
        Notify = "healthy";
        HealthCmd = "curl -s -f http://localhost:8001/api || exit 1";
        HealthInterval = "10s";
        HealthTimeout = "10s";
        HealthRetries = 5;
        HealthStartPeriod = "5s";
      };

      port = 8001;
      traefik.name = name;
      homepage = {
        category = "Media & Downloads";
        name = "Storyteller";
        settings = {
          description = "Immersive Reading Platform";
          icon = "sh-storyteller";
        };
      };
    };
  };
}
