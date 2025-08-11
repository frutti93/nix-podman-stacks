{
  config,
  lib,
  pkgs,
  ...
}: let
  stackName = "streaming";

  toml = pkgs.formats.toml {};

  gluetunName = "gluetun";
  qbittorrentName = "qbittorrent";
  jellyfinName = "jellyfin";
  sonarrName = "sonarr";
  radarrName = "radarr";
  bazarrName = "bazarr";
  prowlarrName = "prowlarr";

  cfg = config.nps.stacks.${stackName};
  storage = "${config.nps.storageBaseDir}/${stackName}";
  mediaStorage = "${config.nps.mediaStorageBaseDir}";

  mkServarrEnv = name: {
    PUID = config.nps.defaultUid;
    PGID = config.nps.defaultGid;
    "${name}__AUTH__METHOD" = "Forms";
    "${name}__AUTH__REQUIRED" = "DisabledForLocalAddresses";
  };
in {
  imports = import ../mkAliases.nix config lib stackName [gluetunName qbittorrentName jellyfinName sonarrName radarrName bazarrName prowlarrName];

  options.nps.stacks.${stackName} =
    {
      enable = lib.mkEnableOption stackName;
      gluetun = {
        enable = lib.mkEnableOption "Gluetun" // {default = true;};
        vpnProvider = lib.mkOption {
          type = lib.types.str;
          description = "The VPN provider to use with Gluetun.";
        };
        envFile = lib.mkOption {
          type = lib.types.path;
          description = ''
            Path to the environment file for Gluetun.
            Should contain Wireguard credentials such as 'WIREGUARD_PRIVATE_KEY', 'WIREGUARD_ADDRESSES'
            and 'WIREGUARD_PRESHARED_KEY'
          '';
        };
        settings = lib.mkOption {
          type = toml.type;
          apply = toml.generate "config.toml";
          description = "Additional Gluetun configuration settings.";
        };
      };
      qbittorrent = {
        enable = lib.mkEnableOption "qBittorrent" // {default = true;};
        envFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "Path to the environment file for qBittorrent.";
        };
      };
      jellyfin.enable = lib.mkEnableOption "Jellyfin" // {default = true;};
      flaresolverr.enable = lib.mkEnableOption "Flaresolverr" // {default = true;};
    }
    // ([sonarrName radarrName bazarrName prowlarrName]
      |> lib.map (name:
        lib.nameValuePair name {
          enable = lib.mkEnableOption name // {default = true;};
          envFile = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = "Path to the environment file for ${name}.";
          };
        })
      |> lib.listToAttrs);

  config = lib.mkIf cfg.enable {
    nps.stacks.streaming.gluetun.settings = import ./gluetun_config.nix;

    services.podman.containers = {
      ${gluetunName} = lib.mkIf cfg.gluetun.enable {
        image = "docker.io/qmcgaw/gluetun:v3.40.0";
        addCapabilities = ["NET_ADMIN"];
        devices = ["/dev/net/tun:/dev/net/tun"];
        volumes = [
          "${storage}/${gluetunName}:/gluetun"
          "${cfg.gluetun.settings}:/gluetun/auth/config.toml"
        ];
        environmentFile = [cfg.gluetun.envFile];
        environment = {
          WIREGUARD_MTU = 1320;
          HTTP_CONTROL_SERVER_LOG = "off";
          VPN_SERVICE_PROVIDER = cfg.gluetun.vpnProvider;
          VPN_TYPE = "wireguard";
          UPDATER_PERIOD = "12h";
          HTTPPROXY = "on";
          HEALTH_VPN_DURATION_INITIAL = "60s";
        };
        network = [config.nps.stacks.traefik.network.name];

        stack = stackName;
        port = 8888;
        homepage = {
          category = "Network & Administration";
          name = "Gluetun";
          settings = {
            description = "VPN client";
            icon = "gluetun";
            widget = {
              type = "gluetun";
              url = "http://${gluetunName}:8000";
            };
          };
        };
      };

      ${qbittorrentName} = lib.mkIf cfg.qbittorrent.enable {
        image = "docker.io/linuxserver/qbittorrent:5.1.2";
        dependsOnContainer = [gluetunName];
        network = lib.mkIf cfg.gluetun.enable (lib.mkForce ["container:${gluetunName}"]);
        volumes = [
          "${storage}/${qbittorrentName}:/config"
          "${mediaStorage}:/media"
        ];
        environmentFile = [cfg.qbittorrent.envFile];
        environment = {
          PUID = config.nps.defaultUid;
          PGID = config.nps.defaultGid;
          UMASK = "022";
          WEBUI_PORT = 8080;
        };

        stack = stackName;
        port = 8080;
        traefik.name = qbittorrentName;
        homepage = {
          category = "Media & Downloads";
          name = "qBittorrent";
          settings = {
            description = "BitTorrent Client";
            icon = "qbittorrent";
            widget.type = "qbittorrent";
          };
        };
      };

      ${jellyfinName} = lib.mkIf cfg.jellyfin.enable {
        image = "lscr.io/linuxserver/jellyfin:10.10.7";
        volumes = [
          "${storage}/${jellyfinName}:/config"
          "${mediaStorage}:/media"
        ];
        devices = ["/dev/dri:/dev/dri"];
        environment = {
          PUID = config.nps.defaultUid;
          PGID = config.nps.defaultGid;
          JELLYFIN_PublishedServerUrl = config.services.podman.containers.${jellyfinName}.traefik.serviceDomain;
        };

        port = 8096;
        stack = stackName;
        traefik.name = jellyfinName;
        homepage = {
          category = "Media & Downloads";
          name = "Jellyfin";
          settings = {
            description = "Media Server";
            icon = "jellyfin";
            widget.type = "jellyfin";
          };
        };
      };

      ${sonarrName} = lib.mkIf cfg.sonarr.enable {
        image = "lscr.io/linuxserver/sonarr:4.0.15";
        volumes = [
          "${storage}/${sonarrName}:/config"
          "${mediaStorage}:/media"
        ];
        environment = mkServarrEnv "SONARR";
        environmentFile = lib.optional (cfg.sonarr.envFile != null) cfg.sonarr.envFile;

        port = 8989;
        stack = stackName;
        traefik.name = sonarrName;
        homepage = {
          category = "Media & Downloads";
          name = "Sonarr";
          settings = {
            description = "Series Management";
            icon = "sonarr";
            widget.type = "sonarr";
          };
        };
      };

      ${radarrName} = lib.mkIf cfg.radarr.enable {
        image = "lscr.io/linuxserver/radarr:5.26.2";
        volumes = [
          "${storage}/${radarrName}:/config"
          "${mediaStorage}:/media"
        ];
        environment = mkServarrEnv "RADARR";
        environmentFile = lib.optional (cfg.radarr.envFile != null) cfg.radarr.envFile;

        port = 7878;
        stack = stackName;
        traefik.name = radarrName;
        homepage = {
          category = "Media & Downloads";
          name = "Radarr";
          settings = {
            description = "Movie Management";
            icon = "radarr";
            widget.type = "radarr";
          };
        };
      };

      ${bazarrName} = lib.mkIf cfg.bazarr.enable {
        image = "lscr.io/linuxserver/bazarr:1.5.2";
        volumes = [
          "${storage}/${bazarrName}:/config"
          "${mediaStorage}:/media"
        ];
        environment = mkServarrEnv "BAZARR";
        environmentFile = lib.optional (cfg.bazarr.envFile != null) cfg.bazarr.envFile;

        port = 6767;
        stack = stackName;
        traefik.name = bazarrName;
        homepage = {
          category = "Media & Downloads";
          name = "Bazarr";
          settings = {
            description = "Subtitle Management";
            icon = "bazarr";
            widget.type = "bazarr";
          };
        };
      };

      ${prowlarrName} = lib.mkIf cfg.prowlarr.enable {
        image = "lscr.io/linuxserver/prowlarr:1.37.0";
        volumes = [
          "${storage}/${prowlarrName}:/config"
        ];
        environment = mkServarrEnv "PROWLARR";
        environmentFile = lib.optional (cfg.prowlarr.envFile != null) cfg.prowlarr.envFile;

        port = 9696;
        stack = stackName;
        traefik.name = prowlarrName;
        homepage = {
          category = "Media & Downloads";
          name = "Prowlarr";
          settings = {
            description = "Indexer Management";
            icon = "prowlarr";
            widget.type = "prowlarr";
          };
        };
      };

      flaresolverr = lib.mkIf cfg.flaresolverr.enable {
        image = "ghcr.io/flaresolverr/flaresolverr:v3.3.25";
        volumes = [
          "${storage}/${prowlarrName}:/config"
        ];
        environment = {
          LOG_LEVEL = "info";
          LOG_HTML = false;
          CAPTCHA_SOLVER = "none";
        };

        stack = stackName;
        homepage = {
          category = "Media & Downloads";
          name = "Flaresolverr";
          settings = {
            icon = "flaresolverr";
            description = "Cloudflare Protection Bypass";
          };
        };
      };
    };
  };
}
