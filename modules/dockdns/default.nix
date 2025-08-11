{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "dockdns";
  cfg = config.nps.stacks.${name};
  yaml = pkgs.formats.yaml {};
in {
  imports =
    [
      ./extension.nix
      (import ../docker-socket-proxy/mkSocketProxyOptionModule.nix {stack = name;})
    ]
    ++ import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable =
      lib.mkEnableOption name
      // {
        description = ''
          Whether to enable DockDNS. This will run a Cloudflare DNS client that updates DNS records based on Docker labels.
          The module contains an extension that will automatically create DNS records for services with the 'public' Traefik middleware,
          so they are accessible from the internet. It will also automatically delete DNS records for services, that are no longer exposed (e.g. 'private' middleware)
        '';
      };
    settings = lib.mkOption {
      type = yaml.type;
      description = ''
        Settings for DockDNS.
        For details, refer to the [DockDNS documentation](https://github.com/Tarow/dockdns?tab=readme-ov-file#configuration)
        The module will provide a default configuration, that updates DNS records every 10 minutes.
        DockDNS labels will be automatically added to services with the 'public' Traefik middleware.
      '';
      apply = yaml.generate "dockdns_config.yaml";
    };
    envFile = lib.mkOption {
      type = lib.types.path;
      default = null;
      description = ''
        Path to a file containing environment variables for the API token for the domain.
        E.g. for a domain 'test.example.com', the file should contain 'TEST_EXAMPLE_COM_API_TOKEN=your_api_token'.'';
    };
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.${name}.settings = lib.mkMerge [
      # Apply all leaf-attributes with default priority.
      # Allows for easy overriding of leaf-attributes
      (import ./config.nix |> lib.mapAttrsRecursive (_: lib.mkDefault))

      (lib.mkIf config.nps.stacks.traefik.enable {
        zones = [
          {
            name = config.nps.stacks.traefik.domain;
            provider = "cloudflare";
          }
        ];
      })
    ];

    services.podman.containers.${name} = {
      image = "ghcr.io/tarow/dockdns:v0.7.0";
      volumes = [
        "${cfg.settings}:/app/config.yaml"
      ];

      environment = {
        DOCKER_HOST = lib.mkIf (cfg.useSocketProxy) config.nps.stacks.docker-socket-proxy.address;
      };
      environmentFile = [cfg.envFile];

      port = 8080;
      traefik.name = name;
      homepage = {
        category = "Network & Administration";
        name = "DockDNS";
        settings = {
          description = "Label-based DNS Client";
          icon = "azure-dns";
        };
      };
    };
  };
}
