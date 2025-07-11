{
  config,
  lib,
  ...
}: let
  name = "adguard";
  storage = "${config.tarow.podman.storageBaseDir}/${name}";
  cfg = config.tarow.podman.stacks.${name};
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.tarow.podman.stacks.${name}.enable = lib.mkEnableOption name;

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "docker.io/adguard/adguardhome:latest";
      volumes = [
        "${storage}/work:/opt/adguardhome/work"
        "${storage}/conf:/opt/adguardhome/conf"
      ];
      ports = let
        ip = config.tarow.podman.hostIP4Address;
      in [
        "${ip}:53:53/tcp"
        "${ip}:53:53/udp"
        "${ip}:853:853/tcp"
      ];
      port = 3000;
      traefik.name = name;
      homepage = {
        category = "Network & Administration";
        name = "AdGuard Home";
        settings = {
          description = "Adblocker";
          icon = "adguard-home";
          widget.type = "adguard";
        };
      };
    };
  };
}
