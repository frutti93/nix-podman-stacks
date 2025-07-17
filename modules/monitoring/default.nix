{
  config,
  lib,
  pkgs,
  ...
}: let
  stackName = "monitoring";
  cfg = config.tarow.podman.stacks.${stackName};
  storage = "${config.tarow.podman.storageBaseDir}/${stackName}";

  yaml = pkgs.formats.yaml {};
  ini = pkgs.formats.ini {};

  grafanaName = "grafana";
  lokiName = "loki";
  prometheusName = "prometheus";
  alloyName = "alloy";
  podmanExporterName = "podman-exporter";

  dashboardPath = "/var/lib/grafana/dashboards";

  dashboards = pkgs.runCommand "grafana-dashboards-dir" {} ''
    mkdir -p "$out"
    for f in ${lib.concatStringsSep " " cfg.grafana.dashboards}; do
      baseName=$(basename "$f")
      cp "$f" "$out/$baseName"
    done
  '';

  lokiUrl = "http://${lokiName}:${toString cfg.loki.port}";
  prometheusUrl = "http://${prometheusName}:${toString cfg.prometheus.port}";
in {
  imports = [./extension.nix] ++ import ../mkAliases.nix config lib stackName [grafanaName lokiName prometheusName alloyName podmanExporterName];

  options.tarow.podman.stacks.${stackName} = {
    enable =
      lib.mkEnableOption stackName
      // {
        description = ''
          Enable the ${stackName} stack.
          This stack provides monitoring services including Grafana, Loki, Alloy, and Prometheus.
          Configuration files for each service will be provided automatically to work out of the box.
        '';
      };
    grafana = {
      enable = lib.mkEnableOption "Grafana" // {default = true;};
      dashboardProvider = lib.mkOption {
        type = yaml.type;
        default = import ./dashboard_provider.nix dashboardPath;
        apply = yaml.generate "dashboard_provider.yml";
        readOnly = true;
        description = ''
          Dashboard provider configuration for Grafana.
        '';
      };
      dashboards = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        default = [];
        description = ''
          List of paths to Grafana dashboard JSON files.
        '';
      };
      datasources = lib.mkOption {
        type = yaml.type;
        default = import ./grafana_datasources.nix lokiUrl prometheusUrl;
        apply = yaml.generate "grafana_datasources.yml";
        readOnly = true;
        description = ''
          Datasource configuration for Grafana.
        '';
      };
      settings = lib.mkOption {
        type = ini.type;
        default = {};
        apply = ini.generate "grafana.ini";
        description = ''
          Settings for Grafana.
          Will be written to the 'grafana.ini' file.
          See <https://grafana.com/docs/grafana/latest/setup-grafana/configure-grafana/#configure-grafana>
        '';
      };
    };
    loki = {
      enable = lib.mkEnableOption "Loki" // {default = true;};
      port = lib.mkOption {
        type = lib.types.port;
        default = 3100;
        visible = false;
      };
      config = lib.mkOption {
        type = yaml.type;
        default = {};
        apply = yaml.generate "loki_config.yaml";
        description = ''
          Configuration for Loki.
          A default configuration will be automatically provided by this monitoring module.

          See <https://grafana.com/docs/loki/latest/configuration/>
        '';
      };
    };
    alloy = {
      enable = lib.mkEnableOption "Alloy" // {default = true;};
      port = lib.mkOption {
        type = lib.types.port;
        default = 12345;
        visible = false;
      };
      config = lib.mkOption {
        type = lib.types.lines;
        default = import ./alloy_config.nix lokiUrl;
        apply = pkgs.writeText "config.alloy";
        description = ''
          Configuration for Alloy.
          A default configuration will be automatically provided by this monitoring module.

          See <https://grafana.com/docs/alloy/latest/get-started/configuration-syntax/>
        '';
      };
    };
    prometheus = {
      enable = lib.mkEnableOption "Prometheus" // {default = true;};
      port = lib.mkOption {
        type = lib.types.port;
        default = 9090;
        visible = false;
      };
      config = lib.mkOption {
        type = yaml.type;
        default = {};
        apply = yaml.generate "prometheus_config.yml";
        description = ''
          Configuration for Prometheus.
          A default configuration will be automatically provided by this monitoring module.

          See <https://prometheus.io/docs/prometheus/latest/configuration/configuration/>
        '';
      };
    };
    podmanExporter.enable = lib.mkEnableOption "Podman Metrics Exporter" // {default = true;};
  };

  config = lib.mkIf cfg.enable {
    tarow.podman.stacks.${stackName} = {
      grafana.dashboards = lib.optional cfg.podmanExporter.enable ./dashboards/podman-exporter.json;
      loki.config = import ./loki_local_config.nix cfg.loki.port;

      prometheus.config = lib.mkMerge [
        (import ./prometheus_config.nix)
        (lib.mkIf
          cfg.podmanExporter.enable
          {
            scrape_configs = [
              {
                job_name = "podman";
                honor_timestamps = true;
                metrics_path = "/metrics";
                scheme = "http";
                static_configs = [{targets = ["${podmanExporterName}:9882"];}];
              }
            ];
          })
      ];
    };

    services.podman.containers = {
      ${grafanaName} = lib.mkIf cfg.grafana.enable {
        image = "docker.io/grafana/grafana:latest";
        user = config.tarow.podman.defaultUid;
        volumes = [
          "${storage}/grafana/data:/var/lib/grafana"
          "${cfg.grafana.settings}:/etc/grafana/grafana.ini"
          "${cfg.grafana.datasources}:/etc/grafana/provisioning/datasources/datasources.yaml"
          "${cfg.grafana.dashboardProvider}:/etc/grafana/provisioning/dashboards/provider.yml"
          "${dashboards}:${dashboardPath}"
        ];

        environment = {
          GF_AUTH_ANONYMOUS_ENABLED = "true";
          GF_AUTH_ANONYMOUS_ORG_ROLE = "Admin";
          GF_AUTH_DISABLE_LOGIN_FORM = "true";
        };

        port = 3000;
        stack = stackName;
        traefik.name = grafanaName;
        homepage = {
          category = "Monitoring";
          name = "Grafana";
          settings = {
            description = "Monitoring & Observability Platform";
            icon = "grafana";
            widget.type = "grafana";
          };
        };
      };

      ${lokiName} = lib.mkIf cfg.loki.enable {
        image = "docker.io/grafana/loki:latest";
        exec = "-config.file=/etc/loki/local-config.yaml";
        user = config.tarow.podman.defaultUid;
        volumes = [
          "${storage}/loki/data:/loki"
          "${cfg.loki.config}:/etc/loki/local-config.yaml"
        ];

        stack = stackName;
        homepage = {
          category = "Monitoring";
          name = "Loki";
          settings = {
            description = "Log Aggregation";
            icon = "loki";
          };
        };
      };

      ${alloyName} = let
        configDst = "/etc/alloy/config.alloy";
      in
        lib.mkIf cfg.alloy.enable {
          image = "docker.io/grafana/alloy:latest";
          volumes = [
            "${cfg.alloy.config}:${configDst}"
            "${config.tarow.podman.socketLocation}:/var/run/docker.sock:ro"
          ];
          exec = "run --server.http.listen-addr=0.0.0.0:${toString cfg.alloy.port} --storage.path=/var/lib/alloy/data ${configDst}";

          stack = stackName;
          inherit (cfg.alloy) port;
          traefik.name = alloyName;
          homepage = {
            category = "Monitoring";
            name = "Alloy";
            settings = {
              description = "Telemetry Collector";
              icon = "alloy";
            };
          };
        };

      ${prometheusName} = let
        configDst = "/etc/prometheus/prometheus.yml";
      in
        lib.mkIf cfg.prometheus.enable {
          image = "docker.io/prom/prometheus:latest";
          exec = "--config.file=${configDst}";
          user = config.tarow.podman.defaultUid;
          volumes = [
            "${storage}/prometheus/data:/prometheus"
            "${cfg.prometheus.config}:${configDst}"
          ];

          port = cfg.prometheus.port;
          stack = stackName;
          traefik.name = "prometheus";
          homepage = {
            category = "Monitoring";
            name = "Prometheus";
            settings = {
              description = "Metrics & Monitoring";
              icon = "prometheus";
              widget.type = "prometheus";
            };
          };
        };

      ${podmanExporterName} = lib.mkIf cfg.podmanExporter.enable {
        image = "quay.io/navidys/prometheus-podman-exporter:latest";
        volumes = [
          "${config.tarow.podman.socketLocation}:/var/run/podman/podman.sock"
        ];
        environment.CONTAINER_HOST = "unix:///var/run/podman/podman.sock";
        user = config.tarow.podman.defaultUid;
        extraPodmanArgs = ["--security-opt=label=disable"];

        stack = stackName;
      };
    };
  };
}
