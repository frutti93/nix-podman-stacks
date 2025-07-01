{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "homeassistant";
  storage = "${config.tarow.podman.storageBaseDir}/${name}";
  yaml = pkgs.formats.yaml {};

  cfg = config.tarow.podman.stacks.${name};

  traefikSubnet = config.tarow.podman.stacks.traefik.subnet;
in {
  imports = import ../mkAliases.nix lib name [name];

  options.tarow.podman.stacks.${name} = {
    enable = lib.mkEnableOption name;
    settings = lib.mkOption {
      type = lib.types.nullOr yaml.type;
      apply = settings:
        if settings != null
        then yaml.generate "configuration.yaml" settings
        else null;
      description = ''
        Settings that will be written to the 'configuration.yaml' file.
        If you want to configure settings through the UI, set this option to null.
        In that case, no managed configuration.yaml will be provided.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    tarow.podman.stacks.homeassistant.settings = {
      default_config = {};

      http = {
        use_x_forwarded_for = true;
        trusted_proxies = [traefikSubnet "127.0.0.1" "::1"];
      };
    };

    services.podman.containers.${name} = {
      image = "ghcr.io/home-assistant/home-assistant:stable";
      volumes =
        [
          "${storage}/config:/config"
          # User should be in 'dialout' group for HA to access bluetooth module
          "/run/dbus:/run/dbus:ro"
        ]
        ++ lib.optional (cfg.settings != null) "${cfg.settings}:/config/configuration.yaml";
      extraConfig.Container.GroupAdd = "keep-groups";

      port = 8123;
      traefik.name = name;
      homepage = {
        category = "General";
        name = "Home Assistant";
        settings = {
          description = "Home Automation";
          icon = "home-assistant";
        };
      };
    };
  };
}
