{
  config,
  pkgs,
  lib,
  ...
}: let
  name = "homepage";
  externalStorage = config.tarow.podman.externalStorageBaseDir;
  cfg = config.tarow.podman.stacks.${name};
  yaml = pkgs.formats.yaml {};

  utils = import ./utils.nix lib;

  deepFilterWidgets = value:
    if lib.isAttrs value
    then
      lib.filterAttrs (
        n: v:
          !(n == "widget" && !(v.enable or false))
      ) (lib.mapAttrs (_: deepFilterWidgets) value)
    else if lib.isList value
    then builtins.map deepFilterWidgets value
    else value;

  # Replace paths values in the configuration with environment variable placeholders
  bookmarks = utils.replacePathsDeep cfg.bookmarks |> yaml.generate "bookmarks";
  services =
    utils.replacePathsDeep cfg.services
    |> deepFilterWidgets
    |> yaml.generate "services";
  settings = utils.replacePathsDeep cfg.settings |> yaml.generate "settings";
  widgets = utils.replacePathsDeep cfg.widgets |> yaml.generate "widgets";
  docker = utils.replacePathsDeep cfg.docker |> yaml.generate "docker";

  # Extract path entries from the configuration to be used as environment variables
  # Will be used to pass environment variables & corresponding paths as volumes to the container
  pathEntries = [cfg.bookmarks cfg.docker cfg.services cfg.settings cfg.widgets] |> map utils.pathEntries |> lib.foldl' (a: b: a // b) {};

  sortByRank = attrs:
    builtins.sort (
      a: b: let
        orderA = attrs.${a}.order or 999;
        orderB = attrs.${b}.order or 999;
      in
        if orderA == orderB
        then (lib.strings.toLower a) < (lib.strings.toLower b)
        else orderA < orderB
    ) (builtins.attrNames attrs);

  toOrderedList = attrs:
    builtins.map (
      groupName: {
        "${groupName}" = builtins.map (
          serviceName: {"${serviceName}" = attrs.${groupName}.${serviceName};}
        ) (sortByRank attrs.${groupName});
      }
    ) (sortByRank attrs);
in {
  imports = [./extension.nix] ++ import ../mkAliases.nix lib name [name];

  options.tarow.podman.stacks.${name} = {
    enable = lib.mkEnableOption name;
    bookmarks = lib.mkOption {
      inherit (yaml) type;
      default = [];
    };
    services = lib.mkOption {
      inherit (yaml) type;
      apply = services: toOrderedList services;
      default = [];
    };
    widgets = lib.mkOption {
      inherit (yaml) type;
      default = [];
    };
    docker = lib.mkOption {
      inherit (yaml) type;
      default = {};
    };
    settings = lib.mkOption {
      inherit (yaml) type;
      default = {};
    };
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "ghcr.io/gethomepage/homepage:latest";
      volumes =
        [
          "${externalStorage}:/ext:ro"
          "${docker}:/app/config/docker.yaml"
          "${services}:/app/config/services.yaml"
          "${settings}:/app/config/settings.yaml"
          "${widgets}:/app/config/widgets.yaml"
          "${bookmarks}:/app/config/bookmarks.yaml"
          "${config.tarow.podman.socketLocation}:/var/run/docker.sock:ro"
        ]
        ++ (lib.attrValues pathEntries |> map (path: "${path}:${path}"));

      environment =
        {
          PUID = config.tarow.podman.defaultUid;
          PGID = config.tarow.podman.defaultGid;
          HOMEPAGE_ALLOWED_HOSTS = config.services.podman.containers.${name}.traefik.serviceHost;
        }
        // pathEntries;

      port = 3000;
      traefik = {
        inherit name;
        subDomain = "";
      };
    };

    tarow.podman.stacks.${name} = {
      docker.local.socket = "/var/run/docker.sock";
      settings.statusStyle = "dot";
      settings.useEqualHeights = true;

      widgets = [
        {
          resources = {
            cpu = true;
            memory = true;
            label = "System";
          };
        }
        {
          resources = {
            disk = "/";
            label = "Storage";
          };
        }
        {
          resources = {
            disk = "/ext";
            label = "External";
          };
        }
        {
          search = {
            provider = "google";
            focus = true;
            target = "_blank";
          };
        }
      ];
    };
  };
}
