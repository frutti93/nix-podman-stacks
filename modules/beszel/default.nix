{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "beszel";
  agentName = "${name}-agent";

  storage = "${config.tarow.podman.storageBaseDir}/${name}";
  cfg = config.tarow.podman.stacks.${name};

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
    ++ import ../mkAliases.nix config lib name [name agentName];

  options.tarow.podman.stacks.${name} = {
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

        The module will automatically provide a configuration to add the local agent to the hub.
      '';
      example = {
        systems = [
          {
            name = "Local";
            host = "/beszel_socket/beszel.sock";
            port = 45876;
            users = [];
          }
        ];
      };
    };
  };
  config = lib.mkIf cfg.enable {
    tarow.podman.stacks.beszel.settings = {
      systems = [
        {
          name = "Local";
          host = "/beszel_socket/beszel.sock";
          port = 45876;
          users = [];
        }
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
          ++ lib.optional (cfg.ed25519PrivateKeyFile != null) "${cfg.ed25519PrivateKeyFile}:/beszel_data/id_ed25519"
          ++ lib.optional (cfg.ed25519PublicKeyFile != null) "${cfg.ed25519PublicKeyFile}:/beszel_data/id_ed25519.pub";

        environment = {
          SHARE_ALL_SYSTEMS = true;
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
        volumes =
          [
            "${storage}/beszel_socket:/beszel_socket"
          ]
          ++ lib.optional (cfg.ed25519PublicKeyFile != null) "${cfg.ed25519PublicKeyFile}:/data/hub_key";

        # No way to connect to socket proxy through host network yet
        # Check traefik tcp router with socket activation eventually
        network =
          if (!cfg.useSocketProxy)
          then ["host"]
          else [config.tarow.podman.stacks.traefik.network.name];

        environment =
          {
            LISTEN = "/beszel_socket/beszel.sock";
            DOCKER_HOST =
              if !cfg.useSocketProxy
              then "unix://${socketTargetLocation}"
              else config.tarow.podman.stacks.docker-socket-proxy.address;
          }
          // lib.optionalAttrs (cfg.ed25519PublicKeyFile != null) {
            KEY_FILE = "/data/hub_key";
          };
      };
    };
  };
}
