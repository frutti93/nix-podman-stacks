{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "crowdsec";
  storage = "${config.tarow.podman.storageBaseDir}/${name}";
  cfg = config.tarow.podman.stacks.${name};

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
        pkgs.writeShellScriptBin "crowdsec-update"
        ([
            "hub update"
            "hub upgrade"
            "collections upgrade -a"
            "parsers upgrade -a"
            "scenarios upgrade -a"
          ]
          |> lib.concatMapStringsSep "\n" (c: "${lib.getExe pkgs.podman} exec ${name} cscli " + c))
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

  options.tarow.podman.stacks.${name} = {
    enable = lib.mkEnableOption name;
    envFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to the env file containing secrets, e.g. the 'ENROLL_INSTANCE_NAME' and 'ENROLL_KEY' variables.
        To automatically monitor Traefik logs and add a Traefik middleware, make sure to configure the `traefikIntegration` options
      '';
    };
    acquisSettings = lib.mkOption {
      type = yaml.type;
      default = {};
      description = ''
        Acquisitions settings for Crowdsec.
        If Traefik is enabled, the module will automatically setup acquisition for Traefik.
      '';
      apply = yaml.generate "acquis.yaml";
    };
    traefikIntegration = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = config.tarow.podman.stacks.traefik.enable;
        defaultText = lib.literalExpression ''config.tarow.podman.stacks.traefik.enable'';
        description = ''
          Wheter to configure aquis settings for Traefik.
          If enabled, Traefik access logs will be automatically collected.

          To also setup a Traefik middleware that makes use of the CrowdSec decisions to block requests, make sure to configure
          the `bouncerEnvFile` option.
        '';
      };
      bouncerEnvFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          Path to env file containing the `BOUNCER_KEY_TRAEFIK` environment variable.
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
        assertion = !cfg.traefikIntegration.enable || config.tarow.podman.stacks.traefik.enable;
        message = "The option 'tarow.podman.stacks.${name}.traefikIntegration.enable' is set to true, but the 'traefik' stack is not enabled.";
      }
    ];

    tarow.podman.stacks.${name}.acquisSettings = lib.mkIf cfg.traefikIntegration.enable {
      source = "docker";
      container_name = ["traefik"];
      labels = {
        type = "traefik";
      };
      docker_host = lib.mkIf cfg.traefikIntegration.useSocketProxy config.tarow.podman.stacks.docker-socket-proxy.address;
    };

    tarow.podman.stacks.traefik = lib.mkIf (cfg.traefikIntegration.enable && cfg.traefikIntegration.bouncerEnvFile != null) {
      containers.traefik.environmentFile = [cfg.traefikIntegration.bouncerEnvFile];
      staticConfig.experimental.plugins.bouncer = {
        moduleName = "github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin";
        version = "v1.4.4";
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
          clientTrustedIPs = ["10.0.0.0/8" "172.16.0.0/12" "192.168.0.0/16"];
        };
      };
    };

    systemd.user = {
      timers."crowdsec-upgrade" = timer;
      services."crowdsec-upgrade" = job;
    };

    services.podman.containers.${name} = {
      image = "docker.io/crowdsecurity/crowdsec:latest";
      volumes = [
        "${storage}/db:/var/lib/crowdsec/data"
        "${storage}/config:/etc/crowdsec"
        "${cfg.acquisSettings}:/etc/crowdsec/acquis.yaml"
        "${config.tarow.podman.socketLocation}:/var/run/docker.sock:ro"
      ];
      environment = {
        COLLECTIONS = "crowdsecurity/traefik crowdsecurity/http-cve crowdsecurity/whitelist-good-actors";
        UID = config.tarow.podman.defaultUid;
        GID = config.tarow.podman.defaultGid;
      };
      environmentFile =
        lib.optional (cfg.envFile != null) cfg.envFile
        ++ lib.optional (cfg.traefikIntegration.enable && cfg.traefikIntegration.bouncerEnvFile != null) cfg.traefikIntegration.bouncerEnvFile;
      network = lib.optional (cfg.traefikIntegration.enable) config.tarow.podman.stacks.traefik.network.name;

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
