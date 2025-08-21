{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "beszel";
  agentName = "${name}-agent";

  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};

  yaml = pkgs.formats.yaml {};

  socketTargetLocation = "/var/run/podman.sock";
in {
  imports =
    [
      (import ../docker-socket-proxy/mkSocketProxyOptionModule.nix {
        stack = name;
        targetLocation = socketTargetLocation;
      })
    ]
    ++ import ../mkAliases.nix config lib name [
      name
      agentName
    ];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    ed25519PrivateKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to private SSH key that will be used by the hub to authenticate against agent
        If not provided, the hub will generate a new key pair when starting.
      '';
    };
    ed25519PublicKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to public SSH key of the hub that will be considered authorized by agent
        If not provided, the `KEY` environment variable should be set to the public key of the hub,
        in order for the connection from hub to agent to work.
      '';
    };

    settings = lib.mkOption {
      type = lib.types.nullOr yaml.type;
      default = null;
      apply = settings:
        if (settings != null)
        then yaml.generate "config.yml" settings
        else null;

      description = ''
        System configuration (optional).
        If provided, on each restart, systems in the database will be updated to match the systems defined in the settings.
        To see your current configuration, refer to settings -> YAML Config -> Export configuration
      '';
      example = {
        systems = [
          {
            name = "Local";
            host = "/beszel_socket/beszel.sock";
            port = 45876;
            users = ["admin@example.com"];
          }
        ];
      };
    };
    authelia = {
      registerClient = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to register a Beszel OIDC client in Authelia.
          If enabled you need to provide a hashed secret in the `client_secret` option.

          To enable OIDC Login for Beszel, you will have to set it up in Beszels Web-UI.
          For details, see:

          - <https://www.authelia.com/integration/openid-connect/clients/beszel/>
          - <https://beszel.dev/guide/oauth>
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
    };
  };
  config = lib.mkIf cfg.enable {
    nps.stacks.authelia.oidc.clients.${name} = lib.mkIf cfg.authelia.registerClient {
      client_name = "Beszel";
      client_secret = cfg.authelia.clientSecretHash;
      public = false;
      authorization_policy = "one_factor";
      require_pkce = true;
      pkce_challenge_method = "S256";
      pre_configured_consent_duration = "1 month";
      redirect_uris = [
        "${cfg.containers.${name}.traefik.serviceDomain}/api/oauth2-redirect"
      ];
    };

    services.podman.containers = {
      ${name} = {
        image = "ghcr.io/henrygd/beszel/beszel:0.12.3";
        volumes =
          [
            "${storage}/data:/beszel_data"
            "${storage}/beszel_socket:/beszel_socket"
          ]
          ++ lib.optional (cfg.settings != null) "${cfg.settings}:/beszel_data/config.yml"
          ++ lib.optional (
            cfg.ed25519PrivateKeyFile != null
          ) "${cfg.ed25519PrivateKeyFile}:/beszel_data/id_ed25519"
          ++ lib.optional (
            cfg.ed25519PublicKeyFile != null
          ) "${cfg.ed25519PublicKeyFile}:/beszel_data/id_ed25519.pub";

        environment = {
          SHARE_ALL_SYSTEMS = true;
          # If Authelia is enabled, allow automatic user creation on OIDC login.
          USER_CREATION = cfg.authelia.registerClient;
        };

        port = 8090;
        traefik.name = name;
        homepage = {
          category = "Monitoring";
          name = "Beszel";
          settings = {
            description = "Lightweight Monitoring Platform";
            icon = "beszel";
          };
        };
      };

      ${agentName} = {
        image = "ghcr.io/henrygd/beszel/beszel-agent:0.12.3";
        volumes = [
          "${storage}/beszel_socket:/beszel_socket"
        ];
        fileEnvMount.KEY_FILE = lib.mkIf (cfg.ed25519PublicKeyFile != null) cfg.ed25519PublicKeyFile;

        # No way to connect to socket proxy through host network yet
        # Check traefik tcp router with socket activation eventually
        network =
          if (!cfg.useSocketProxy)
          then ["host"]
          else [config.nps.stacks.traefik.network.name];

        environment = {
          LISTEN = "/beszel_socket/beszel.sock";
          DOCKER_HOST =
            if !cfg.useSocketProxy
            then "unix://${socketTargetLocation}"
            else config.nps.stacks.docker-socket-proxy.address;
        };
      };
    };
  };
}
