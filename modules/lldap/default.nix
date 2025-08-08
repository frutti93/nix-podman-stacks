{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "lldap";
  cfg = config.tarow.podman.stacks.${name};
  storage = "${config.tarow.podman.storageBaseDir}/${name}";

  toml = pkgs.formats.toml {};
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.tarow.podman.stacks.${name} = {
    enable = lib.mkEnableOption name;
    settings = lib.mkOption {
      type = lib.types.nullOr toml.type;
      apply = toml.generate "lldap_config.toml";
      description = ''
        Additional lldap configuration.
        If provided, will be mounted as `lldap_config.toml`;

        See <https://github.com/lldap/lldap/blob/main/lldap_config.docker_template.toml>
      '';
    };
    adminUsername = lib.mkOption {
      type = lib.types.str;
      default = "admin";
      description = ''
        Admin username for LDAP as well as the web interface.
      '';
    };
    baseDn = lib.mkOption {
      type = lib.types.str;
      default = "DC=example,DC=com";
      description = ''
        The starting point in the LDAP directory tree from which searches begin.
      '';
      example = "DC=mydomain,DC=net";
    };
    bindDn = lib.mkOption {
      type = lib.types.str;
      default = "CN=${cfg.adminUsername},OU=people," + cfg.baseDn;
      defaultText = lib.literalExpression ''"CN=''${cfg.adminUsername},OU=people," + cfg.baseDn'';
      description = ''
        The default DN (Distinguished Name) of the entry used to authenticate to the LDAP server.
        Can be used by other programs such as Authelia or PocketID.
      '';
    };
    address = lib.mkOption {
      type = lib.types.str;
      default = "ldap://${name}:3890";
      readOnly = true;
      visible = false;
    };
    envFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the environment file for LLDAP.
        The file should contain the following environment variables:
        - `LLDAP_JWT_SECRET`
        - `LLDAP_KEY_SEED`
        - `LLDAP_LDAP_USER_PASS`
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    tarow.podman.stacks.${name}.settings = {
      ldap_base_dn = cfg.baseDn;
      ldap_user_dn = cfg.adminUsername;
      database_url = "sqlite:///db/users.db?mode=rwc";
    };

    services.podman.containers.${name} = {
      # Always use rootless images here with root-user, because otherwise chown on the read-only
      # lldap_config.toml will be attemped which fails

      # renovate: versioning=regex:^(?<major>[\d-]+)-(?<compatibility>.+)$
      image = "ghcr.io/lldap/lldap:2025-07-29-alpine-rootless";
      user = config.tarow.podman.defaultUid;
      volumes = [
        "${storage}/db:/db"
        "${cfg.settings}:/data/lldap_config.toml"
      ];
      environmentFile = [cfg.envFile];

      port = 17170;
      traefik.name = name;
      homepage = {
        category = "Network & Administration";
        name = "LLDAP";
        settings = {
          description = "Light LDAP Implementation";
          icon = "sh-lldap";
        };
      };
    };
  };
}
