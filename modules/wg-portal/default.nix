{
  config,
  lib,
  pkgs,
  ...
}:
let
  name = "wg-portal";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};
  yaml = pkgs.formats.yaml { };
in
{
  imports = import ../mkAliases.nix config lib name [ name ];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    settings = lib.mkOption {
      type = yaml.type;
      description = ''
        Settings for the wg-portal container.
        Will be converted to YAML and passed to the container.

        See <https://wgportal.org/latest/documentation/configuration/overview/>
      '';
      apply = yaml.generate "config.yaml";
      example = {
        core = {
          admin = {
            username = "admin";
            # ADMIN_PASSWORD will be set from the extraEnv option
            password = "\${ADMIN_PASSWORD}";
          };
        };
      };
    };
    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = { };
      description = ''
        Extra environment variables to set for the container.
        Variables can be either set directly or sourced from a file (e.g. for secrets).

        Can be used to pass secrets or other environment variables that are referenced in the settings.
      '';
      example = {
        ADMIN_PASSWORD = {
          fromFile = "/run/secrets/secret_name";
        };
      };
    };
    port = lib.mkOption {
      type = lib.types.port;
      description = ''
        The default port for the first Wireguard interface that will be set up in the UI.
        Will be exposed and passed as the 'start_listen_port' setting in the configuration.
      '';
      default = 51820;
    };
    authelia = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable OIDC login with Authelia. This will register an OIDC client in Authelia
          and setup the necessary configuration.

          For details, see:

          - <https://wgportal.org/master/documentation/configuration/examples/#openid-connect-oidc-authentication>
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

  config =
    let
      wgAdminGroupName = "wg_portal_admin";
    in
    lib.mkIf cfg.enable {
      nps.stacks.lldap.bootstrap.groups = lib.mkIf (cfg.authelia.enable) {
        ${wgAdminGroupName} = { };
      };

      nps.stacks.authelia = lib.mkIf cfg.authelia.enable {
        oidc.clients.${name} = {
          client_name = "WG-Portal";
          client_secret = cfg.authelia.clientSecretHash;
          public = false;
          authorization_policy = "one_factor";
          claims_policy = name;
          require_pkce = false;
          pkce_challenge_method = "";
          pre_configured_consent_duration = "1 month";
          redirect_uris = [
            "${cfg.containers.${name}.traefik.serviceDomain}/api/v0/auth/login/authelia/callback"
          ];
        };
        settings.identity_providers.oidc.claims_policies.${name}.id_token = [
          "email"
          "name"
          "groups"
          "preferred_username"
        ];
      };

      nps.stacks.${name}.settings = {
        web.external_url = cfg.containers.${name}.traefik.serviceDomain;
        advanced.start_listen_port = cfg.port;
      }
      // lib.optionalAttrs cfg.authelia.enable {
        auth.oidc = [
          {
            id = "authelia";
            provider_name = "authelia";
            display_name = "Login with</br>Authelia";
            base_url = config.nps.containers.authelia.traefik.serviceDomain;
            client_id = name;
            client_secret = "\${AUTHELIA_CLIENT_SECRET}";
            extra_scopes = [
              "openid"
              "email"
              "profile"
              "groups"
            ];
            field_map = {
              user_identifier = "preferred_username";
              email = "email";
              firstname = "given_name";
              lastname = "family_name";
              user_groups = "groups";
            };
            admin_mapping = {
              admin_group_regex = "^${wgAdminGroupName}$";
            };
            registration_enabled = true;
          }
        ];
      };

      services.podman.containers.${name} = {
        image = "ghcr.io/h44z/wg-portal:v2.0.4";
        volumes = [
          "${storage}/data:/app/data"
          "${cfg.settings}:/app/config/config.yaml"
        ];
        ports = [ "${toString cfg.port}:${toString cfg.port}/udp" ];
        addCapabilities = [
          "NET_ADMIN"
          "NET_RAW"
          "SYS_MODULE"
        ];
        extraPodmanArgs = [
          "--sysctl=net.ipv4.conf.all.src_valid_mark=1"
          "--sysctl=net.ipv4.ip_forward=1"
          "--sysctl=net.ipv6.conf.all.disable_ipv6=0"
          "--sysctl=net.ipv6.conf.all.forwarding=1"
          "--sysctl=net.ipv6.conf.default.forwarding=1"
        ];
        extraEnv =
          cfg.extraEnv
          // lib.optionalAttrs cfg.authelia.enable {
            AUTHELIA_CLIENT_SECRET.fromFile = cfg.authelia.clientSecretFile;
          };

        port = 8888;
        traefik = {
          name = name;
          subDomain = "wg";
        };
        homepage = {
          category = "Network & Administration";
          name = "Wireguard Portal";
          settings = {
            description = "Wireguard Management UI";
            icon = "wireguard";
          };
        };
      };
    };
}
