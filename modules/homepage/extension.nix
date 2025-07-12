{
  config,
  lib,
  pkgs,
  ...
}: let
  yaml = pkgs.formats.yaml {};

  homepageContainers =
    lib.filterAttrs (k: c: c.homepage.enable && c.homepage.settings != {})
    config.services.podman.containers;

  mergedServices =
    builtins.foldl' (
      acc: c: let
        container = c.value;
        category = container.homepage.category;
        serviceName = container.homepage.name;
        serviceSettings = container.homepage.settings;
        existingServices = acc.${category} or {};
      in
        acc
        // {
          "${category}" = existingServices // {"${serviceName}" = serviceSettings;};
        }
    ) {}
    (lib.attrsToList homepageContainers);
in {
  imports = [
    {
      tarow.podman.stacks.homepage.services = mergedServices;
    }
  ];

  options.services.podman.containers = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule ({
      name,
      config,
      ...
    }: {
      options.homepage = with lib; {
        enable = options.mkEnableOption "homepage" // {default = true;};
        category = options.mkOption {
          type = types.nullOr types.str;
          default = null;
        };
        name = options.mkOption {
          type = types.nullOr types.str;
          default = null;
        };
        settings = options.mkOption {
          type = yaml.type;
          default = {};
        };
      };

      config = lib.mkIf (config.homepage.name != null) {
        homepage.settings = {
          href = lib.mkIf (config.traefik.name != null) (lib.mkDefault config.traefik.serviceDomain);
          server = lib.mkDefault "local";
          container = lib.mkDefault name;
          widget = {
            enable = lib.mkDefault false;
            url = lib.mkDefault "http://${name}:${toString config.port}";
          };
        };
      };
    }));
  };
}
