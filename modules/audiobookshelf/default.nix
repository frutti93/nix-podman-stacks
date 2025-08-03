{
  config,
  lib,
  ...
}: let
  name = "audiobookshelf";
  storage = "${config.tarow.podman.storageBaseDir}/${name}";
  mediaStorage = config.tarow.podman.mediaStorageBaseDir;
  cfg = config.tarow.podman.stacks.${name};
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.tarow.podman.stacks.${name}.enable = lib.mkEnableOption name;

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "ghcr.io/advplyr/audiobookshelf:2.27.0";
      volumes = [
        "${mediaStorage}/audiobooks:/audiobooks"
        "${storage}/podcasts:/podcasts"
        "${storage}/metadata:/metadata"
        "${storage}/config:/config"
      ];
      port = 80;
      traefik.name = name;
      homepage = {
        category = "Media & Downloads";
        name = "Audiobookshelf";
        settings = {
          description = "Audiobook & Podcast Server";
          icon = "audiobookshelf";
          widget.type = "audiobookshelf";
        };
      };
    };
  };
}
