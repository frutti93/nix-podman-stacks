{
  config,
  lib,
  ...
}: let
  name = "microbin";
  storage = "${config.tarow.podman.storageBaseDir}/${name}";
  cfg = config.tarow.podman.stacks.${name};
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.tarow.podman.stacks.${name} = {
    enable = lib.mkEnableOption name;
    envFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to env file passed to the container.
        Can be used to optionally pass secrets such as 'MICROBIN_ADMIN_USERNAME',
        'MICROBIN_ADMIN_PASSWORD', 'MICROBIN_BASIC_AUTH_USERNAME', 'MICROBIN_BASIC_AUTH_PASSWORD' &
        'MICROBIN_UPLOADER_PASSWORD'.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "docker.io/danielszabo99/microbin:latest";
      volumes = [
        "${storage}/data:/app/microbin_data"
      ];
      environment = {
        MICROBIN_PUBLIC_PATH = cfg.containers.${name}.traefik.serviceDomain;
        MICROBIN_ENABLE_BURN_AFTER = true;
        MICROBIN_QR = true;
        MICROBIN_ENCRYPTION_CLIENT_SIDE = true;
        MICROBIN_ENCRYPTION_SERVER_SIDE = true;
        # False enables enternal pastas: https://github.com/szabodanika/m/issues/270
        MICROBIN_ETERNAL_PASTA = false;
        MICROBIN_ENABLE_READONLY = true;
        MICROBIN_DISABLE_TELEMETRY = true;
        # Requires MICROBIN_UPLOADER_PASSWORD (e.g. in envFile) to take effect
        MICROBIN_READONLY = true;
      };
      environmentFile = lib.optional (cfg.envFile != null) cfg.envFile;

      port = 8080;
      traefik.name = name;
      homepage = {
        category = "General";
        name = "MicroBin";
        settings = {
          description = "Pastebin";
          icon = "microbin";
        };
      };
    };
  };
}
