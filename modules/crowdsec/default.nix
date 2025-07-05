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
  imports = import ../mkAliases.nix lib name [name];

  options.tarow.podman.stacks.${name} = {
    enable = lib.mkEnableOption name;
    envFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to the env file containing the 'BOUNCER_KEY_TRAEFIK' and optionally the
        'ENROLL_INSTANCE_NAME' and 'ENROLL_KEY' variables
      '';
    };
    acquisSettings = lib.mkOption {
      type = yaml.type;
      description = "Acquisitions settings for Crowdsec.";
      apply = yaml.generate "acquis.yaml";
    };
  };

  config = lib.mkIf cfg.enable {
    tarow.podman.stacks.${name}.acquisSettings = import ./acquis.nix;
    tarow.podman.stacks.traefik = {
      staticConfig.experimental.plugins.bouncer = {
        moduleName = "github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin";
        version = "v1.4.4";
      };
      dynamicConfig.http.middlewares = {
        public-chain.chain.middlewares = lib.mkAfter ["crowdsec"];

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
      environmentFile = lib.optional (cfg.envFile != null) cfg.envFile;

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
