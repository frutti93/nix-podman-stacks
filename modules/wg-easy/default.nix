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
      description = ''
        The external domain or IP address of the Wireguard server.
        Will be used as the 'endpoint' when generating client configurations.

        Only has an effect during initial setup.
        See <https://wg-easy.github.io/wg-easy/v15.1/advanced/config/unattended-setup/>
      '';
      default =
        if config.tarow.podman.stacks.traefik.enable
        then "vpn.${config.tarow.podman.stacks.traefik.domain}"
        else config.tarow.podman.hostIP4Address;
      defaultText = lib.literalExpression ''"vpn.''${config.tarow.podman.stacks.traefik.domain}"'';
    };
    port = lib.mkOption {
      type = lib.types.port;
      description = ''
        The port on which the Wireguard server will listen.
        Will be passed as INIT_PORT during initial setup.
        Only has an effect during initial setup.
        See <https://wg-easy.github.io/wg-easy/v15.1/advanced/config/unattended-setup/>
      '';
      default = 51825;
    };
    envFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      description = ''
        Path to the environment file.
        Can be used to pass secrets, e.g. 'INIT_PASSWORD'.
      '';
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "ghcr.io/wg-easy/wg-easy:15";
      volumes = [
        "${storage}/config:/etc/wireguard"
      ];

      ports = ["${toString cfg.port}:${toString cfg.port}/udp"];
      addCapabilities = ["NET_ADMIN" "NET_RAW" "SYS_MODULE"];
      extraPodmanArgs = [
        "--sysctl=net.ipv4.conf.all.src_valid_mark=1"
        "--sysctl=net.ipv4.ip_forward=1"
        "--sysctl=net.ipv6.conf.all.disable_ipv6=0"
        "--sysctl=net.ipv6.conf.all.forwarding=1"
        "--sysctl=net.ipv6.conf.default.forwarding=1"
      ];
      environmentFile = lib.optional (cfg.envFile != null) cfg.envFile;
      environment = {
        INIT_ENABLED = true;
        INIT_HOST = cfg.host;
        INIT_USERNAME = "admin";
        INIT_PORT = cfg.port;
        INIT_DNS = "1.1.1.1,8.8.8.8";
        INIT_IPV4_CIDR = "172.20.0.0/24";
        INIT_IPV6_CIDR = "2001:0DB8::/32";
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
