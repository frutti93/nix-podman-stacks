{
  lib,
  config,
  pkgs,
  ...
}: let
  name = "traefik";
  cfg = config.tarow.podman.stacks.${name};

  yaml = pkgs.formats.yaml {};

  storage = "${config.tarow.podman.storageBaseDir}/${name}";
in {
  imports =
    [./extension.nix] ++ import ../mkAliases.nix lib name [name];

  options.tarow.podman.stacks.${name} = {
    enable = lib.options.mkEnableOption name;
    domain = lib.options.mkOption {
      type = lib.types.str;
      description = "Base domain handled by Traefik";
    };
    network = lib.options.mkOption {
      type = lib.types.str;
      description = "Network name of the Traefik docker provider";
      default = "traefik-proxy";
    };
    staticConfig = lib.options.mkOption {
      type = yaml.type;
      apply = yaml.generate "traefik.yml";
    };
    dynamicConfig = lib.options.mkOption {
      type = yaml.type;
      apply = yaml.generate "dynamic.yml";
    };
    envFile = lib.options.mkOption {
      type = lib.types.path;
      description = "Path to the environment file for Traefik";
    };
  };

  config = lib.mkIf cfg.enable {
    tarow.podman.stacks.${name} = {
      staticConfig = import ./config/traefik.nix cfg.domain cfg.network;
      dynamicConfig = import ./config/dynamic.nix;
    };

    services.podman.networks.${cfg.network} = {
      driver = "bridge";
      extraPodmanArgs = [
      ];
    };

    services.podman.containers.${name} = rec {
      image = "docker.io/traefik:v3";

      socketActivation = [
        {
          port = 80;
          fileDescriptorName = "web";
        }
        {
          port = 443;
          fileDescriptorName = "websecure";
        }
      ];
      ports = [
        #"443:443"
        #"80:80"
      ];
      environmentFile = [cfg.envFile];
      volumes = [
        "${storage}/letsencrypt:/letsencrypt"
        "${config.tarow.podman.socketLocation}:/var/run/docker.sock:ro"
        "${cfg.staticConfig}:/etc/traefik/traefik.yml:ro"
        "${cfg.dynamicConfig}:/dynamic/config.yml"
        "${./config/IP2LOCATION-LITE-DB1.IPV6.BIN}:/plugins/geoblock/IP2LOCATION-LITE-DB1.IPV6.BIN"
      ];
      labels = {
        "traefik.http.routers.${traefik.name}.service" = "api@internal";
      };

      traefik.name = name;
      alloy.enable = true;
      homepage = {
        category = "Network & Administration";
        name = "Traefik";
        settings = {
          description = "Reverse Proxy";
          href = "https://${name}.${cfg.domain}";
          icon = "traefik";
          widget.type = "traefik";
        };
      };
    };
  };
}
