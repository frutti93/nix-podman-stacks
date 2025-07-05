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
    traefik = {
      envFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          Environment file being passed to the Traefik container.
          If this is set, a 'pocketid' middleware will be registered in Traefik
          In order to work, the environment file should contain the secrets
          'POCKET_ID_CLIENT_ID', 'POCKET_ID_CLIENT_SECRET' & 'OIDC_MIDDLEWARE_SECRET'
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    tarow.podman.stacks.traefik = lib.mkIf (cfg.traefik.envFile != null) {
      containers.traefik = {
        # Add host gateway route for pocket id domain, so that the oidc middleware can connect to it
        extraConfig.Container.AddHost = "${cfg.containers.${name}.traefik.serviceHost}:host-gateway";
        environmentFile = [cfg.traefik.envFile];
      };

      staticConfig.experimental.plugins.traefik-oidc-auth = {
        moduleName = "github.com/sevensolutions/traefik-oidc-auth";
        version = "v0.13.0";
      };
      dynamicConfig.http.middlewares = {
        pocketid.plugin.traefik-oidc-auth = {
          Secret = ''{{env "OIDC_MIDDLEWARE_SECRET"}}'';
          Provider = {
            Url = "http://${name}:1411";
            ClientId = ''{{env "POCKET_ID_CLIENT_ID"}}'';
            ClientSecret = ''{{env "POCKET_ID_CLIENT_SECRET"}}'';
          };
          Scopes = ["openid" "profile" "email"];
        };
      };
    };

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
