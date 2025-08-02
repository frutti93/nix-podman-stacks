{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "blocky";
  cfg = config.tarow.podman.stacks.${name};

  yaml = pkgs.formats.yaml {};

  ip = config.tarow.podman.hostIP4Address;
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.tarow.podman.stacks.${name} = {
    enable = lib.mkEnableOption name;
    settings = lib.mkOption {
      type = yaml.type;
      apply = yaml.generate "config.yml";
      description = ''
        Blocky configuration. Will be converted to the `config.yml`.
        For a full list of options, refer to the [Blocky documentation](https://0xerr0r.github.io/blocky/main/configuration/)

        By default, if Traefik is enabled, the module will automatically setup a DNS override
        pointing the Traefik domain to your host IP.
      '';
    };
    enableGrafanaDashboard = lib.mkEnableOption "Grafana Dashboard";
    enablePrometheusExport = lib.mkEnableOption "Prometheus Export";
  };

  config = lib.mkIf cfg.enable {
    tarow.podman.stacks.${name}.settings = lib.mkMerge [
      (import ./settings.nix)
      (lib.mkIf config.tarow.podman.stacks.traefik.enable {
        customDNS.mapping.${config.tarow.podman.stacks.traefik.domain} = ip;
      })
      (lib.mkIf cfg.enablePrometheusExport {
        prometheus.enable = true;
      })
    ];
    tarow.podman.stacks.monitoring.grafana = lib.mkIf cfg.enableGrafanaDashboard {
      dashboards = [./grafana_dashboard.json];
      settings.panels.disable_sanitize_html = true;
    };
    tarow.podman.stacks.monitoring.prometheus.config = lib.mkIf cfg.enablePrometheusExport {
      scrape_configs = [
        {
          job_name = "blocky";
          honor_timestamps = true;
          metrics_path = "/metrics";
          scheme = "http";
          static_configs = [{targets = ["${name}:4000"];}];
        }
      ];
    };

    services.podman.containers.${name} = {
      image = "ghcr.io/0xerr0r/blocky:v0.26.2";
      volumes = [
        "${cfg.settings}:/app/config.yml"
      ];
      ports = [
        "${ip}:53:53/udp"
        "${ip}:53:53/tcp"
      ];
      port = 4000;
      traefik.name = name;
      homepage = {
        category = "Network & Administration";
        name = "Blocky";
        settings = {
          description = "Adblocker";
          icon = "blocky";
        };
      };
    };
  };
}
