{
  config,
  lib,
  options,
  ...
}: let
  name = "vaultwarden";
  storage = "${config.tarow.podman.storageBaseDir}/${name}";
  cfg = config.tarow.podman.stacks.${name};
in {
  imports = [./extension.nix] ++ import ../mkAliases.nix lib name [name];

  options.tarow.podman.stacks.${name} = {
    enable = lib.mkEnableOption name;
    env = lib.mkOption {
      type = (options.services.podman.containers.type.getSubOptions []).environment.type;
      default = {};
      description = "Additional environment variables passed to the container";
    };
    envFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Environment file passed to the container. Can be used to pass secrets such as
        'ADMIN_TOKEN;
        For a list of all environment variables refer to https://github.com/dani-garcia/vaultwarden/blob/main/.env.template
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "ghcr.io/dani-garcia/vaultwarden:latest";
      volumes = [
        "${storage}/data:/data"
      ];
      environment =
        {
          DOMAIN = cfg.containers.${name}.traefik.serviceDomain;
        }
        // cfg.env;
      environmentFile = lib.optional (cfg.envFile != null) cfg.envFile;

      port = 80;
      traefik.name = "vw";
      homepage = {
        category = "General";
        name = "Vaultwarden";
        settings = {
          description = "Password Vault";
          icon = "vaultwarden";
        };
      };
    };
  };
}
