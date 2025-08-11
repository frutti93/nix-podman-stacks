{
  config,
  lib,
  ...
}: let
  name = "filebrowser";
  storage = "${config.nps.storageBaseDir}/${name}";
  externalStorage = config.nps.externalStorageBaseDir;
  cfg = config.nps.stacks.${name};
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    mounts = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      apply = lib.mapAttrs (k: v: builtins.replaceStrings ["//"] ["/"] "/srv/${v}");
      description = ''
        Mount points for the file browser.
        Format: `{ 'hostPath' = 'containerPath' }`
        By default, the users home directory and the external storage directory (`config.nps.externalStorageBaseDir`)
        are configured as mounts.
      '';
      example = {
        "/mnt/ext/data" = "/data";
        "/home/foo/media" = "/media";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.${name}.mounts = {
      ${externalStorage} = "/ext";
      ${config.home.homeDirectory} = "/home";
    };

    services.podman.containers.${name} = {
      image = "docker.io/filebrowser/filebrowser:v2.42.3-s6";
      volumes =
        [
          "${storage}/database:/database"
          "${storage}/config:/config"
        ]
        ++ lib.mapAttrsToList (k: v: "${k}:${v}") cfg.mounts;

      environment = {
        PUID = config.nps.defaultUid;
        PGID = config.nps.defaultGid;
      };
      port = 80;
      traefik.name = name;
      homepage = {
        category = "General";
        name = "File Browser";
        settings = {
          description = "Web-based File Manager";
          icon = "filebrowser";
        };
      };
    };
  };
}
