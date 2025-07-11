{
  config,
  lib,
  ...
}: let
  name = "calibre";
  storage = "${config.tarow.podman.storageBaseDir}/${name}";
  cfg = config.tarow.podman.stacks.${name};
in {
  imports = import ../mkAliases.nix config lib name [name "${name}-downloader" "cloudflarebypassforscraping"];

  options.tarow.podman.stacks.${name}.enable = lib.mkEnableOption name;

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "docker.io/crocodilestick/calibre-web-automated:latest";
      volumes = [
        "${storage}/config:/config"
        "${storage}/ingest:/cwa-book-ingest"
        "${storage}/library:/calibre-library"
      ];
      environment = {
        PUID = config.tarow.podman.defaultUid;
        PGID = config.tarow.podman.defaultGid;
      };
      port = 8083;

      stack = name;
      traefik.name = name;
      homepage = {
        category = "General";
        name = "Calibre Web";
        settings = {
          description = "Ebook Library";
          icon = "calibre-web";
          widget.type = "calibreweb";
        };
      };
    };

    services.podman.containers."${name}-downloader" = let
      ingestDir = "/cwa-book-ingest";
      port = 8084;
    in {
      image = "ghcr.io/calibrain/calibre-web-automated-book-downloader:latest";
      environment = {
        FLASK_PORT = port;
        FLASK_DEBUG = false;
        INGEST_DIR = ingestDir;
        APP_ENV = "prod";
        BOOK_LANGUAGE = "en,de";
        UID = config.tarow.podman.defaultUid;
        GID = config.tarow.podman.defaultGid;
      };
      volumes = [
        "${storage}/ingest:${ingestDir}"
      ];

      port = port;
      stack = name;
      traefik.name = "calibre-downloader";
      homepage = {
        category = "General";
        name = "Calibre Web Book Downloader";
        settings = {
          description = "Book Downloader for Calibre Web";
          icon = "sh-cwa-book-downloader";
        };
      };
    };
  };
}
