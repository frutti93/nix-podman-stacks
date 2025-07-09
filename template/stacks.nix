{
  config,
  lib,
  ...
}: {
  tarow.podman = {
    hostIP4Address = "192.168.178.2";
    hostUid = 1000;
    storageBaseDir = "${config.home.homeDirectory}/stacks";
    externalStorageBaseDir = "/mnt/hdd";

    stacks = {
      adguard.enable = true;
      aiostreams = {
        enable = true;
        envFile = config.sops.secrets."aiostreams/env".path;
      };
      audiobookshelf.enable = true;
      beszel = {
        enable = true;
        ed25519PrivateKeyFile = config.sops.secrets."beszel/ssh_key".path;
        ed25519PublicKeyFile = config.sops.secrets."beszel/ssh_pub_key".path;
      };
      blocky = {
        enable = false;
        enableGrafanaDashboard = true;
        enablePrometheusExport = true;
      };
      calibre.enable = true;
      changedetection.enable = true;
      crowdsec = {
        enable = true;
        envFile = config.sops.secrets."crowdsec/env".path;
      };
      dozzle.enable = true;
      filebrowser.enable = true;
      forgejo.enable = false;
      freshrss.enable = false;
      healthchecks = {
        enable = true;
        envFile = config.sops.secrets."healthchecks/env".path;
      };
      homeassistant.enable = true;
      homepage.enable = true;
      immich = {
        enable = true;
        envFile = config.sops.secrets."immich/env".path;
        db.envFile = config.sops.secrets."immich/db_env".path;
      };
      ittools.enable = true;
      karakeep = {
        enable = true;
        envFile = config.sops.secrets."karakeep/env".path;
      };
      monitoring.enable = true;
      ntfy = {
        enable = true;
        envFile = config.sops.secrets."ntfy/env".path;
      };
      paperless = {
        enable = true;
        envFile = config.sops.secrets."paperless/env".path;
        db.envFile = config.sops.secrets."paperless/db_env".path;
        ftp.envFile = config.sops.secrets."paperless/ftp_env".path;
      };
      pocketid = {
        enable = true;
        traefik.envFile = config.sops.secrets."pocketId/traefikEnv".path;
      };
      stirling-pdf.enable = true;
      streaming = {
        enable = true;
        gluetun = {
          vpnProvider = "airvpn";
          envFile = config.sops.secrets."gluetun/env".path;
        };
        qbittorrent.envFile = config.sops.secrets."qbittorrent/env".path;
      };
      traefik = {
        enable = true;
        domain = "mydomain.com";
        envFile = config.sops.secrets."traefik/env".path;
        geoblock.allowedCountries = ["DE"];
      };
      uptime-kuma.enable = true;
      vaultwarden.enable = true;
      wg-easy = {
        enable = true;
        envFile = config.sops.secrets."wg-easy/env".path;
      };
    };
  };
}
