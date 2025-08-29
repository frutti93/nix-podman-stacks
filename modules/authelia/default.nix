{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "authelia";
  cfg = config.nps.stacks.${name};

  storage = "${config.nps.storageBaseDir}/${name}";

  yaml = pkgs.formats.yaml {};

  # Write this file manually, otherwise there will be single quotes around the key, breaking the file after templating
  writeOidcJwksConfigFile = oidcIssuerPrivateKeyFile:
    pkgs.writeText "oidc-jwks.yaml" ''
      identity_providers:
        oidc:
          jwks:
            - key: {{ secret "${oidcIssuerPrivateKeyFile}" | mindent 10 "|" | msquote }}
    '';

  oidcEnabled = cfg.oidc.enable && (lib.length (lib.attrValues cfg.oidc.clients) > 0);
  container = cfg.containers.${name};
  lldap = config.nps.stacks.lldap;
in {
  imports = [./extension.nix] ++ import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    jwtSecretFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the file containing the JWT secret.
        See <https://www.authelia.com/configuration/identity-validation/reset-password/#jwt_secret>
      '';
    };
    sessionSecretFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the file containing the session secret.
        See <https://www.authelia.com/configuration/session/introduction/#secret>
      '';
    };
    storageEncryptionKeyFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the file containing the storage encryption key.
        See <https://www.authelia.com/configuration/storage/introduction/#encryption_key>
      '';
    };
    oidc = {
      enable = lib.mkEnableOption "OIDC Support";
      hmacSecretFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          Path to the file containing the HMAC secret.
          See <https://www.authelia.com/configuration/identity-providers/openid-connect/provider/#hmac_secret>
        '';
      };
      jwksRsaKeyFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          Path to the file containing the JWKS RSA (RS256) private key.

          For example, a keypair can be generated and printed out like this:
          ```sh
          podman run --rm authelia/authelia sh -c "authelia crypto certificate rsa generate --common-name authelia.example.com && cat public.crt && cat private.pem"
          ```

          See <https://www.authelia.com/configuration/identity-providers/openid-connect/provider/#key>
        '';
      };
      clients = lib.mkOption {
        description = ''
          OIDC client configuration.
          See <https://www.authelia.com/configuration/identity-providers/openid-connect/clients/>
        '';
        default = [];
        type = lib.types.attrsOf (
          lib.types.submodule (
            {name, ...}: {
              freeformType = yaml.type;
              options = {
                client_id = lib.mkOption {
                  type = lib.types.str;
                  default = name;
                };
              };
            }
          )
        );
      };
    };
    settings = lib.mkOption {
      type = yaml.type;
      apply = yaml.generate "configuration.yml";
      description = ''
        Additional Authelia settings. Will be provided in the `configuration.yml`.
      '';
    };

    ldap = {
      user = lib.mkOption {
        type = lib.types.str;
        default = config.nps.stacks.lldap.adminUsername;
        defaultText = lib.literalExpression ''config.nps.stacks.lldap.adminUsername'';
        description = ''
          The username that will be used when binding to the LDAP backend.
        '';
      };
      passwordFile = lib.mkOption {
        type = lib.types.path;
        default = config.nps.stacks.lldap.adminPasswordFile;
        defaultText = lib.literalExpression ''config.nps.stacks.lldap.adminPasswordFile'';
        description = ''
          The password for the LDAP user that is used when connecting to the LDAP backend.
        '';
      };
    };

    enableTraefikMiddleware = lib.mkOption {
      type = lib.types.bool;
      default = config.nps.stacks.traefik.enable;
      defaultText = lib.literalExpression ''config.nps.stacks.traefik.enable'';
      description = ''
        Wheter to register an `authelia` middleware for Traefik.
        The middleware will utilize the ForwardAuth Authz implementation.

        See <https://www.authelia.com/integration/proxies/traefik/#implementation>
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.nps.stacks.lldap.enable;
        message = "Authelia requires the `lldap` stack to be enabled";
      }
    ];

    nps.stacks.${name}.settings = {
      identity_providers = lib.mkIf oidcEnabled {
        oidc = {
          jwks = [
            {
              algorithm = "RS256";
              use = "sig";
              # Key will written in extra config file to avoid templating issues
            }
          ];
          lifespans = {
            access_token = "1h";
            authorize_code = "1m";
            id_token = "1h";
            refresh_token = "90m";
          };
          clients = lib.attrValues cfg.oidc.clients;
        };
      };

      authentication_backend = {
        ldap = {
          address = lldap.address;
          implementation = "lldap";
          base_dn = lldap.baseDn;
          user = "CN=${cfg.ldap.user},OU=people," + lldap.baseDn;
        };

        refresh_interval = "1m";

        # Disable password reset/change if the lldap users are bootstrapped and cleanup is enabled (they will reset on each apply)
        password_reset.disable = config.nps.stacks.lldap.bootstrap.cleanUp;
        password_change.disable = config.nps.stacks.lldap.bootstrap.cleanUp;
      };
      access_control.default_policy = "one_factor";
      notifier.filesystem.filename = "/notifier/notification.txt";
      session = {
        name = "authelia_session";
        same_site = "lax";
        inactivity = "5m";
        expiration = "1h";
        remember_me = "1M";
        cookies = [
          {
            domain = config.nps.stacks.traefik.domain;
            authelia_url = container.traefik.serviceUrl;
            name = "authelia_session";
          }
        ];
      };

      server = lib.mkIf cfg.enableTraefikMiddleware {
        endpoints.authz.forward-auth.implementation = "ForwardAuth";
      };
      webauthn.enable_passkey_login = true;
    };

    nps.stacks.traefik = lib.mkIf cfg.enableTraefikMiddleware {
      containers.traefik.wantsContainer = [name];
      dynamicConfig.http.middlewares.authelia.forwardAuth = {
        address = "http://authelia:9091/api/authz/forward-auth?authelia_url=https%3A%2F%2F${
          cfg.containers.${name}.traefik.serviceHost
        }%2F";
        trustForwardHeader = true;
        authResponseHeaders = "Remote-User,Remote-Groups,Remote-Email,Remote-Name";
      };
    };

    services.podman.containers.${name} = {
      image = "ghcr.io/authelia/authelia:4.39.6";
      environment =
        {
          AUTHELIA_STORAGE_LOCAL_PATH = "/data/db.sqlite3";
        }
        // lib.optionalAttrs oidcEnabled {
          X_AUTHELIA_CONFIG_FILTERS = "template";
          X_AUTHELIA_CONFIG = "/config/configuration.yml,/config/jwks_key_config.yml";
        };

      fileEnvMount =
        {
          AUTHELIA_IDENTITY_VALIDATION_RESET_PASSWORD_JWT_SECRET_FILE = cfg.jwtSecretFile;
          AUTHELIA_STORAGE_ENCRYPTION_KEY_FILE = cfg.storageEncryptionKeyFile;
          AUTHELIA_SESSION_SECRET_FILE = cfg.sessionSecretFile;
          AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = cfg.ldap.passwordFile;
        }
        // lib.optionalAttrs oidcEnabled {
          IDENTITY_PROVIDERS_OIDC_HMAC_SECRET_FILE = cfg.oidc.hmacSecretFile;
        };

      volumes =
        [
          "${storage}/db:/data"
          "${storage}/notifier:/notifier"
          "${cfg.settings}:/config/configuration.yml"
        ]
        ++ lib.optionals oidcEnabled [
          "${cfg.oidc.jwksRsaKeyFile}:/secrets/oidc/jwks/rsa.key"
          "${writeOidcJwksConfigFile "/secrets/oidc/jwks/rsa.key"}:/config/jwks_key_config.yml"
        ];

      port = 9091;
      traefik.name = name;
      homepage = {
        category = "Network & Administration";
        name = "Authelia";
        settings = {
          description = "Authentication & Authorization Server";
          icon = "authelia";
        };
      };
    };
  };
}
