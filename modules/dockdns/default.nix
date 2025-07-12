{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "dockdns";
  cfg = config.tarow.podman.stacks.${name};
  yaml = pkgs.formats.yaml {};
in {
  imports = [./extension.nix] ++ import ../mkAliases.nix config lib name [name];

  options.tarow.podman.stacks.${name} = {
    enable = lib.mkEnableOption name;
    settings = lib.mkOption {
      type = yaml.type;
      description = "Settings for DockDNS.";
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
    tarow.podman.stacks.${name}.settings = lib.mkMerge [
      (import ./config.nix)
      (lib.mkIf config.tarow.podman.stacks.traefik.enable {
        zones = [
          {
            name = config.tarow.podman.stacks.traefik.domain;
            provider = "cloudflare";
          }
        ];
      })
    ];

    services.podman.containers.${name} = {
      image = "ghcr.io/tarow/dockdns:latest";
      volumes = [
        "${cfg.settings}:/app/config.yaml"
        "${config.tarow.podman.socketLocation}:/var/run/docker.sock:ro"
      ];

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
