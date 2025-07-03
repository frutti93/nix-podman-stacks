{
  config,
  lib,
  ...
}: let
  name = "pocketid";
  storage = "${config.tarow.podman.storageBaseDir}/${name}";
  cfg = config.tarow.podman.stacks.${name};
in {
  imports = import ../mkAliases.nix lib name [name];

  options.tarow.podman.stacks.${name} = {
    enable = lib.mkEnableOption name;
    envFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Environment file being passed to the container. Can be used to pass additional variables such
        as 'MAXMIND_LICENSE_KEY'. Refer to https://pocket-id.org/docs/configuration/environment-variables/
        for a full list of available variables
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "ghcr.io/pocket-id/pocket-id:v1";
      volumes = [
        "${storage}/data:/app/data"
      ];
      environment = {
        PUID = config.tarow.podman.defaultUid;
        PGID = config.tarow.podman.defaultGid;
        TRUST_PROXY = true;
        APP_URL = cfg.containers.${name}.traefik.serviceDomain;
        ANALYTICS_DISABLED = true;
      };

      port = 1411;
      traefik.name = name;
      homepage = {
        category = "Network & Administration";
        name = "Pocket ID";
        settings = {
          description = "Simple OIDC Provider";
          icon = "pocket-id";
        };
      };
    };
  };
}
