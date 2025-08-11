{
  config,
  lib,
  options,
  ...
}: let
  name = "bytestash";
  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    env = lib.mkOption {
      type = (options.services.podman.containers.type.getSubOptions []).environment.type;
      default = {};
      description = ''
        Additional environment variables passed to the ByteStash container.
        Can be used to override the preset.

        See <https://docs.romm.app/latest/Getting-Started/Environment-Variables/>
      '';
    };
    envFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to the environment file containing atleast the 'JWT_SECRET' variable.

        See <https://github.com/jordan-dalby/ByteStash/wiki/FAQ#environment-variables>
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "ghcr.io/jordan-dalby/bytestash:1.5.8";

      volumes = ["${storage}/snippets:/data/snippets"];
      environment =
        {
          BASE_PATH = "";
          TOKEN_EXPIRY = "24h";
          ALLOW_NEW_ACCOUNTS = false;
          DISABLE_ACCOUNTS = false;
          DISABLE_INTERNAL_ACCOUNTS = false;
          ALLOW_PASSWORD_CHANGES = true;
          DEBUG = false;
        }
        // cfg.env;
      environmentFile = lib.optional (cfg.envFile != null) cfg.envFile;

      port = 5000;
      traefik.name = name;
      homepage = {
        category = "General";
        name = "ByteStash";
        settings = {
          description = "Code Snippets Organizer";
          icon = "bytestash";
        };
      };
    };
  };
}
