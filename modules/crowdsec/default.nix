{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "crowdsec";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};

  yaml = pkgs.formats.yaml {};

  timer = {
    Timer = {
      OnCalendar = "01:30";
      Persistent = true;
    };
    Install = {
      WantedBy = ["timers.target"];
    };
  };
  job = {
    Service = {
      Type = "oneshot";
      ExecStart = lib.getExe (
        pkgs.writeShellScriptBin "crowdsec-update" (
          [
            "hub update"
            "hub upgrade"
            "collections upgrade -a"
            "parsers upgrade -a"
            "scenarios upgrade -a"
          ]
          |> lib.concatMapStringsSep "\n" (c: "${lib.getExe pkgs.podman} exec ${name} cscli " + c)
        )
      );
    };
  };
in {
  imports =
    [
      # Create the `traefikIntegration.useSocketProxy` option
      (import ../docker-socket-proxy/mkSocketProxyOptionModule.nix {
        stack = name;
        subPath = "traefikIntegration";
      })
    ]
    ++ import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    settings = lib.mkOption {
      type = yaml.type;
      default = {};
      description = ''
        Configuration settings for Crowdsec.
        Will be provided as the `config.yaml.local` file.

        See <https://docs.crowdsec.net/docs/configuration/crowdsec_configuration/>

      '';
      apply = yaml.generate "config.yaml.local";
    };
    acquisSettings = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        freeformType = yaml.type;
        options = {
          source = lib.mkOption {
            type = lib.types.str;
            description = "Which type of datasource to use.";
            example = "docker";
          };
          log_level = lib.mkOption {
            type = lib.types.str;
            default = "info";
            description = "Log level to use in the datasource";
          };
          labels = lib.mkOption {
            type = lib.types.submodule {
              freeformType = yaml.type;
              options = {
                type = lib.mkOption {
                  type = lib.types.str;
                };
              };
            };
            default = {};
            description = ''
              A map of labels to add to the event. The type label is mandatory, and used by the Security Engine to choose which parser to use.

              See <https://docs.crowdsec.net/docs/next/log_processor/data_sources/intro#labels>
            '';
          };
        };
      });
      default = {};
      description = ''
        Acquisitions settings for Crowdsec.
        Each attribute set value will be mapped to an acquis configuration and mounted into the `/etc/crowdsec/acquis.d` directory.

        See <https://docs.crowdsec.net/docs/next/log_processor/data_sources/intro> for all available options.
      '';
      apply = lib.mapAttrs (name: settings: yaml.generate "${name}-acquis.yaml" settings);
    };
    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.
        Variables can be either set directly or sourced from a file (e.g. for secrets).

        See <https://github.com/crowdsecurity/crowdsec/blob/master/docker/README.md#environment-variables>
      '';
      example = {
        SOME_SECRET = {
          fromFile = "/run/secrets/secret_name";
        };
        FOO = "bar";
      };
    };
    enableGrafanaDashboard = lib.mkEnableOption "Grafana Dashboard";
    enablePrometheusExport = lib.mkEnableOption "Prometheus Export";
    traefikIntegration = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = config.nps.stacks.traefik.enable;
        defaultText = lib.literalExpression ''config.nps.stacks.traefik.enable'';
        description = ''
          Wheter to configure aquis settings for Traefik.
          If enabled, Traefik access logs will be automatically collected.

          To also setup a Traefik middleware that makes use of the CrowdSec decisions to block requests, make sure to configure
          the `bouncerKey` option.
        '';
      };
      bouncerKeyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          Path to the file containing the key for the Traefik bouncer.
          If this is set, a Bouncer will be setup in CrowdSec. Also a new `crowdsec` middleware will be registered in Traefik and added to the 'public' chain.
          This will block requests to exposed services that are detected as malicious by Crowdsec.
        '';
      };
      # useSocketProxy option is configured by the imported module
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.traefikIntegration.enable || config.nps.stacks.traefik.enable;
        message = "The option 'nps.stacks.${name}.traefikIntegration.enable' is set to true, but the 'traefik' stack is not enabled.";
      }
    ];

    nps.stacks.monitoring.prometheus.config = lib.mkIf cfg.enablePrometheusExport {
      scrape_configs = [
        {
          job_name = "crowdsec";
          honor_timestamps = true;
          metrics_path = "/metrics";
          scheme = "http";
          static_configs = [
            {
              targets = [(name + ":6060")];
              labels = {machine = "lapi";};
            }
          ];
        }
      ];
    };
    nps.stacks.monitoring.grafana.dashboards = lib.optional cfg.enableGrafanaDashboard ./grafana_dashboard.json;

    nps.stacks.${name} = {
      settings = {
        prometheus = {
          enabled = cfg.enablePrometheusExport;
          level = "full";
          listen_addr = "0.0.0.0";
          listen_port = 6060;
        };
      };
      acquisSettings.traefik = lib.mkIf cfg.traefikIntegration.enable {
        source = "docker";
        container_name = ["traefik"];
        labels = {
          type = "traefik";
        };
        docker_host = lib.mkIf cfg.traefikIntegration.useSocketProxy config.nps.stacks.docker-socket-proxy.address;
      };
    };

    nps.stacks.traefik =
      lib.mkIf (cfg.traefikIntegration.enable && cfg.traefikIntegration.bouncerKeyFile != null)
      {
        containers.traefik.extraEnv = lib.mkIf (cfg.traefikIntegration.bouncerKeyFile != null) {
          BOUNCER_KEY_TRAEFIK.fromFile = cfg.traefikIntegration.bouncerKeyFile;
        };
        containers.traefik.wantsContainer = [name];
        staticConfig.experimental.plugins.bouncer = {
          moduleName = "github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin";
          version = "v1.4.5";
        };
        dynamicConfig.http.middlewares = {
          public.chain.middlewares = lib.mkAfter ["crowdsec"];

          crowdsec.plugin.bouncer = {
            enabled = true;
            logLevel = "INFO";
            updateIntervalSeconds = 60;
            updateMaxFailure = 0;
            defaultDecisionSeconds = 60;
            httpTimeoutSeconds = 10;
            crowdsecMode = "live";
            crowdsecAppsecEnabled = false;
            crowdsecAppsecHost = "crowdsec:7422";
            crowdsecAppsecPath = "/";
            crowdsecAppsecFailureBlock = true;
            crowdsecAppsecUnreachableBlock = true;
            crowdsecAppsecBodyLimit = 10485760;
            crowdsecLapiKey = "{{ env \"BOUNCER_KEY_TRAEFIK\" }}";
            crowdsecLapiScheme = "http";
            crowdsecLapiHost = "crowdsec:8080";
            crowdsecLapiPath = "/";
            clientTrustedIPs = [
              "10.0.0.0/8"
              "172.16.0.0/12"
              "192.168.0.0/16"
            ];
          };
        };
      };

    systemd.user = {
      timers."crowdsec-upgrade" = timer;
      services."crowdsec-upgrade" = job;
    };

    services.podman.containers.${name} = {
      image = "docker.io/crowdsecurity/crowdsec:v1.6.11";
      volumes =
        [
          "${storage}/db:/var/lib/crowdsec/data"
          "${storage}/config:/etc/crowdsec"
          "${cfg.settings}:/etc/crowdsec/config.yaml.local"
        ]
        ++ (lib.mapAttrsToList (name: file: "${file}:/etc/crowdsec/acquis.d/${name}.yaml") cfg.acquisSettings);
      environment = {
        COLLECTIONS = "crowdsecurity/traefik crowdsecurity/http-cve crowdsecurity/whitelist-good-actors";
        UID = config.nps.defaultUid;
        GID = config.nps.defaultGid;
      };
      extraEnv =
        lib.optionalAttrs (cfg.traefikIntegration.bouncerKeyFile != null) {
          BOUNCER_KEY_TRAEFIK.fromFile = cfg.traefikIntegration.bouncerKeyFile;
        }
        // cfg.extraEnv;

      network = lib.optional (cfg.traefikIntegration.enable) config.nps.stacks.traefik.network.name;

      homepage = {
        category = "Network & Administration";
        name = "Crowdsec";
        settings = {
          description = "Collaborative Security Threat Prevention";
          icon = "crowdsec";
          widget = {
            type = "crowdsec";
            url = "http://${name}:8080";
          };
        };
      };
    };
  };
}
