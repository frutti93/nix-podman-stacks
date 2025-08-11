{
  config,
  lib,
  ...
}: let
  name = "uptime-kuma";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};
in {
  imports = import ../mkAliases.nix config lib name [name];
  options.nps.stacks.${name}.enable = lib.mkEnableOption name;

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "ghcr.io/louislam/uptime-kuma:beta";
      volumes = [
        "${storage}/data:/app/data"
        "${config.nps.socketLocation}:/var/run/docker.sock:ro"
      ];
      environment = {
        UPTIME_KUMA_DB_TYPE = "sqlite";
        PUID = config.nps.defaultUid;
        PGID = config.nps.defaultGid;
      };
      labels = {"traefik.http.routers.${name}.entrypoints" = "websecure,websecure-internal";};

      port = 3001;
      traefik = {
        inherit name;
        subDomain = "uptime";
      };
      homepage = {
        category = "Monitoring";
        name = "Uptime Kuma";
        settings = {
          description = "Uptime Monitoring";
          icon = "uptime-kuma";
          widget.type = "uptimekuma";
        };
      };
    };
  };
}
