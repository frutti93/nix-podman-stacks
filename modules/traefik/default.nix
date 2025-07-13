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
    [./extension.nix] ++ import ../mkAliases.nix config lib name [name];

  options.tarow.podman.stacks.${name} = {
    enable = lib.options.mkEnableOption name;
    domain = lib.options.mkOption {
      type = lib.types.str;
      description = "Base domain handled by Traefik";
    };
    network = lib.options.mkOption {
      type = lib.types.str;
      description = "Network name for Podman bridge network. Will be used by the Traefik Docker provider";
      default = "traefik-proxy";
    };
    subnet = lib.options.mkOption {
      type = lib.types.str;
      description = "Subnet of the Podman bridge network";
      default = "10.80.0.0/24";
    };
    staticConfig = lib.options.mkOption {
      type = yaml.type;
      default = {};
      apply = yaml.generate "traefik.yml";
    };
    dynamicConfig = lib.options.mkOption {
      type = yaml.type;
      default = {};
    };
    envFile = lib.options.mkOption {
      type = lib.types.path;
      description = "Path to the environment file for Traefik";
    };
    geoblock = {
      enable = lib.mkEnableOption "Geoblock" // {default = true;};
      allowedCountries = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = ''
          List of allowed country codes (ISO 3166-1 alpha-2 format)
        '';
      };
    };
    enablePrometheusExport = lib.mkEnableOption "Prometheus Export";
    enableGrafanaMetricsDashboard = lib.mkEnableOption "Grafana Metrics Dashboard";
    enableGrafanaAccessLogDashboard = lib.mkEnableOption "Grafana Access Log Dashboard";
  };

  config = lib.mkIf cfg.enable {
    tarow.podman.stacks.${name} = {
      staticConfig = lib.mkMerge [
        (import ./config/traefik.nix cfg.domain cfg.network)
        (lib.mkIf cfg.enablePrometheusExport {
          entryPoints.metrics.address = ":9100";
          metrics.prometheus.entryPoint = "metrics";
        })
      ];
      dynamicConfig = lib.mkMerge [
        (
          import ./config/dynamic.nix
        )
        (lib.mkIf cfg.geoblock.enable {
          http.middlewares = {
            public-chain.chain.middlewares = lib.mkOrder 1100 ["geoblock"];
            geoblock.plugin.geoblock = {
              enabled = true;
              databaseFilePath = "/plugins/geoblock/IP2LOCATION-LITE-DB1.IPV6.BIN";
              allowedCountries = cfg.geoblock.allowedCountries;
              defaultAllow = false;
              allowPrivate = true;
              disallowedStatusCode = 403;
            };
          };
        })
      ];
    };
    tarow.podman.stacks.monitoring = {
      grafana.dashboards =
        (lib.optional cfg.enableGrafanaAccessLogDashboard ./grafana/access_log_dashboard.json)
        ++ (lib.optional cfg.enableGrafanaMetricsDashboard ./grafana/metrics_dashboard.json);
      prometheus.config.scrape_configs = lib.optional cfg.enablePrometheusExport {
        job_name = "traefik";
        honor_timestamps = true;
        metrics_path = "/metrics";
        scheme = "http";
        static_configs = [{targets = ["${name}:9100"];}];
      };
    };

    services.podman.networks.${cfg.network} = {
      driver = "bridge";
      subnet = cfg.subnet;
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
      environmentFile = [cfg.envFile];
      volumes = [
        "${storage}/letsencrypt:/letsencrypt"
        "${config.tarow.podman.socketLocation}:/var/run/docker.sock:ro"
        "${cfg.staticConfig}:/etc/traefik/traefik.yml:ro"
        "${yaml.generate "dynamic.yml" cfg.dynamicConfig}:/dynamic/config.yml"
        "${./config/IP2LOCATION-LITE-DB1.IPV6.BIN}:/plugins/geoblock/IP2LOCATION-LITE-DB1.IPV6.BIN"
      ];
      labels = {
        "traefik.http.routers.${traefik.name}.service" = "api@internal";
      };

      # For every container that we manage, add a NetworkAlias, so that connections to Traefik are possible
      # trough the internal podman network (no host-gateway required)
      extraConfig.Container.NetworkAlias =
        config.services.podman.containers
        |> lib.attrValues
        |> lib.filter (c: c.traefik.name != null)
        |> lib.map (c: c.traefik.serviceHost);

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
