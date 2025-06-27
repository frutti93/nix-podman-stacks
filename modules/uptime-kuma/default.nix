{
  config,
  lib,
  ...
}: let
  name = "uptime-kuma";
  storage = "${config.tarow.podman.storageBaseDir}/${name}";
  cfg = config.tarow.podman.stacks.${name};
in {
  imports = import ../mkAliases.nix lib name [name];
  options.tarow.podman.stacks.${name}.enable = lib.mkEnableOption name;

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "ghcr.io/louislam/uptime-kuma:beta";
      volumes = [
        "${storage}/data:/app/data"
        "${config.tarow.podman.socketLocation}:/var/run/docker.sock:ro"
      ];
      environment = {
        UPTIME_KUMA_DB_TYPE = "sqlite";
        PUID = config.tarow.podman.defaultUid;
        PGID = config.tarow.podman.defaultGid;
      };

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
