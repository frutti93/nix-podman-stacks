{
  config,
  lib,
  ...
}: let
  name = "wg-easy";
  storage = "${config.tarow.podman.storageBaseDir}/${name}";
  cfg = config.tarow.podman.stacks.${name};
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.tarow.podman.stacks.${name} = {
    enable = lib.mkEnableOption name;
    host = lib.mkOption {
      type = lib.types.str;
      description = "The external domain or IP address of the Wireguard server.";
      default =
        if config.tarow.podman.stacks.traefik.enable
        then "vpn.${config.tarow.podman.stacks.traefik.domain}"
        else config.tarow.podman.hostIP4Address;
    };
    envFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      description = "Path to the environment file for Wireguard Easy.";
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "ghcr.io/wg-easy/wg-easy:latest";
      volumes = [
        "${storage}/config:/etc/wireguard"
      ];

      ports = ["51820:51820/udp"];
      addCapabilities = ["NET_ADMIN" "NET_RAW" "SYS_MODULE"];
      extraPodmanArgs = [
        "--sysctl=net.ipv4.conf.all.src_valid_mark=1"
        "--sysctl=net.ipv4.ip_forward=1"
      ];
      environmentFile = lib.optional (cfg.envFile != null) cfg.envFile;
      environment = {
        WG_HOST = cfg.host;
        WG_DEFAULT_DNS = "1.1.1.1";
        WG_DEFAULT_ADDRESS = "172.20.0.x";
      };

      port = 51821;
      traefik = {
        name = name;
        subDomain = "wg";
      };
      homepage = {
        category = "Network & Administration";
        name = "Wireguard";
        settings = {
          description = "VPN Server";
          icon = "wireguard";
          widget = {
            type = "wgeasy";
            version = 2;
          };
        };
      };
    };
  };
}
