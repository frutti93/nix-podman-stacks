{
  config,
  lib,
  ...
}:
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";

    secrets = lib.genAttrs [
      "aiostreams/env"
      "beszel/ssh_key"
      "beszel/ssh_pub_key"
      "bytestash/env"
      "crowdsec/env"
      "crowdsec/traefikBouncerEnv"
      "dockdns/env"
      "gluetun/env"
      "healthchecks/env"
      "immich/env"
      "immich/db_env"
      "karakeep/env"
      "microbin/env"
      "ntfy/env"
      "paperless/env"
      "paperless/db_env"
      "paperless/ftp_env"
      "pocketid/traefikEnv"
      "qbittorrent/env"
      "romm/env"
      "romm/db_env"
      "wg-easy/env"
      "traefik/env"
    ] (s: { });
  };
}
