{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "filebrowser-quantum";
  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";
  yaml = pkgs.formats.yaml {};
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    mounts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            path = lib.mkOption {
              type = lib.types.path;
              description = "Path of the source in the container";
              example = "/mnt/folder";
            };
            name = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              description = "Optional name of the source, otherwise the source gets named the folder name";
              default = null;
              example = "folder";
            };
            config = lib.mkOption {
              type = lib.types.submodule {
                freeformType = yaml.type;
              };
              default = {};
              description = ''
                Additional configuration options for the source.

                See <https://github.com/gtsteffaniak/filebrowser/wiki/Configuration-And-Examples#example-advanced-source-config>
              '';
            };
          };
        }
      );
      default = {};
      description = ''
        Mount configuration for the file browser.
        Format: `{ 'hostPath' = container-source-config }`

        The mounts will be added to the settings `source` section and a volume mount will be added for each configured source.

        See <https://github.com/gtsteffaniak/filebrowser/wiki/Configuration-And-Examples#example-advanced-source-config>
      '';
      example = {
        "/mnt/ext/data" = {
          path = "/data";
          name = "ext-data";
        };
        "/home/foo/media" = {
          path = "/media";
          config = {
            disableIndexing = false;
            exclude = {
              fileEndsWith = [".zip" ".txt"];
            };
          };
        };
      };
    };
    settings = lib.mkOption {
      type = yaml.type;
      description = ''
        Settings that will be added to the `config.yml`.
        To configure sources, you should prefer using the `mounts` option, as the corresponding volume mappings will be
        configured automatically.

        See <https://github.com/gtsteffaniak/filebrowser/wiki/Configuration-And-Examples#configuring-your-application>
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.filebrowser-quantum.settings = {
      server = {
        port = 80;
        baseURL = "/";
        logging = [
          {levels = "warning";}
        ];
        sources = lib.attrValues cfg.mounts;
      };
      userDefaults = {
        preview = {
          image = true;
          popup = true;
          video = false;
          office = false;
          highQuality = false;
        };
        darkMode = true;
        disableSettings = false;
        singleClick = false;
        permissions = {
          admin = false;
          modify = false;
          share = false;
          api = false;
        };
      };
    };

    services.podman.containers.${name} = {
      image = "ghcr.io/gtsteffaniak/filebrowser:0.8.3-beta";
      volumes =
        [
          "${yaml.generate "config.yml" cfg.settings}:/home/filebrowser/config.yml"
          "${storage}/db:/home/filebrowser/db"
        ]
        ++ lib.mapAttrsToList (k: v: "${k}:${v.path}") cfg.mounts;

      environment = {
        FILEBROWSER_CONFIG = "/home/filebrowser/config.yml";
        FILEBROWSER_DATABASE = "/home/filebrowser/db/database.db";
      };
      port = 80;
      traefik.name = name;
      homepage = {
        category = "General";
        name = "FileBrowser Quantum";
        settings = {
          description = "Web-based File Manager";
          icon = "filebrowser-quantum";
        };
      };
    };
  };
}
