{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "freshrss";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    adminProvisioning = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Whether to automatically create an admin user on the first run.
          If set to false, you will be prompted to create an admin user when visiting the FreshRSS web interface for the first time.
          This only affects the first run of the container.
        '';
      };
      username = lib.mkOption {
        type = lib.types.str;
        default = "admin";
        description = "Username for the admin user";
      };
      email = lib.mkOption {
        type = lib.types.str;
        description = "Email address for the admin user ";
      };
      passwordFile = lib.mkOption {
        type = lib.types.path;
        default = null;
        description = "Path to a file containing the admin user password";
      };
      apiPasswordFile = lib.mkOption {
        type = lib.types.path;
        default = null;
        description = "Path to a file containing the admin API password";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "docker.io/freshrss/freshrss:1.27.0";
      volumes = [
        "${storage}/data:/var/www/FreshRSS/data"
        "${storage}/extensions:/var/www/FreshRSS/extensions"
      ];

      extraEnv =
        {
          CRON_MIN = "3,33";
          TRUSTED_PROXY = config.nps.stacks.traefik.network.subnet;
        }
        // lib.optionalAttrs (cfg.adminProvisioning.enable) {
          ADMIN_USERNAME = cfg.adminProvisioning.username;
          ADMIN_EMAIL = cfg.adminProvisioning.email;
          ADMIN_PASSWORD.fromFile = cfg.adminProvisioning.passwordFile;
          ADMIN_API_PASSWORD.fromFile = cfg.adminProvisioning.apiPasswordFile;

          FRESHRSS_INSTALL = "'${
            lib.concatStringsSep " " [
              "--api-enabled"
              "--base-url ${cfg.containers.${name}.traefik.serviceUrl}"
              "--default-user \\$\\$\{ADMIN_USERNAME\}"
              "--language en"
            ]
          }'";

          FRESHRSS_USER = "'${
            lib.concatStringsSep " " [
              "--api-password \\$\\$\{ADMIN_API_PASSWORD\}"
              "--email \\$\\$\{ADMIN_EMAIL\}"
              "--language en"
              "--password \\$\\$\{ADMIN_PASSWORD\}"
              "--user \\$\\$\{ADMIN_USERNAME\}"
            ]
          }'";
        };

      port = 80;
      traefik.name = name;
      homepage = {
        category = "General";
        name = "FreshRSS";
        settings = {
          description = "Feeds Aggregator";
          icon = "freshrss";
        };
      };
    };
  };
}
