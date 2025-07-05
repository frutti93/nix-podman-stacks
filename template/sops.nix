{
  config,
  lib,
  ...
}: {
  sops = {
    defaultSopsFile = ./secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";

    secrets =
      lib.genAttrs
      [
        "aiostreams/env"
        "beszel/ssh_key"
        "beszel/ssh_pub_key"
        "crowdsec/env"
        "dockdns/env"
        "healthchecks/env"
        "immich/env"
        "immich/db_env"
        "gluetun/env"
        "qbittorrent/env"
        "paperless/env"
        "paperless/db_env"
        "paperless/ftp_env"
        "pocketId/traefikEnv"
        "wg-easy/env"
        "traefik/env"
      ] (s: {});
  };
}
