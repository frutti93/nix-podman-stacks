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
  json = pkgs.formats.json {};

  mkEnvSecret = envName: srcPath: let
    dstPath = "/run/secrets/env/${builtins.baseNameOf srcPath}";
  in
    if srcPath == null
    then {
      volume = [];
      env = {};
      dstPath = null;
    }
    else {
      volume = ["${srcPath}:${dstPath}"];
      env.${envName} = dstPath;
      dstPath = dstPath;
    };

  mkUserPasswordSecret = userId: srcPath: let
    dstPath = "/run/secrets/users/${userId}_pw";
  in
    if srcPath == null
    then {
      volume = [];
      dstPath = null;
    }
    else {
      volume = ["${srcPath}:${dstPath}"];
      dstPath = dstPath;
    };

  jwtSecret = mkEnvSecret "LLDAP_JWT_SECRET_FILE" cfg.jwtSecretFile;
  keySeedSecret = mkEnvSecret "LLDAP_KEY_SEED_FILE" cfg.keySeedFile;
  adminPasswordSecret = mkEnvSecret "LLDAP_LDAP_USER_PASS_FILE" cfg.adminPasswordFile;

  userPasswordFiles =
    cfg.bootstrap.users
    |> map (u: lib.nameValuePair u.id (mkUserPasswordSecret u.id (u.password_file or null)))
    |> lib.listToAttrs
    |> lib.filterAttrs (_: v: v.dstPath != null);

  userConfigsDir = "/bootstrap/user-configs";
  groupConfigsDir = "/bootstrap/group-configs";

  finalUserVolumes =
    cfg.bootstrap.users
    |> map (u: lib.filterAttrs (_: v: v != null) (u // {password_file = userPasswordFiles.${u.id}.dstPath or null;}))
    |> map (u: "${json.generate "${u.id}.json" u}:${userConfigsDir}/${u.id}.json");

  finalGroupVolumes =
    cfg.bootstrap.groups
    |> map (g: {name = g;})
    |> map (g: "${json.generate "${g.name}.json" g}:${groupConfigsDir}/${g.name}.json");

  bootstrapWrapper = pkgs.writeTextFile {
    name = "bootstrap_wrapper.sh";
    executable = true;
    text = ''
      #!/usr/bin/env bash
      export LLDAP_ADMIN_USERNAME="${cfg.adminUsername}"
      export LLDAP_ADMIN_PASSWORD="$(cat ${adminPasswordSecret.dstPath})"
      export USER_CONFIGS_DIR="${userConfigsDir}"
      export GROUP_CONFIGS_DIR="${groupConfigsDir}"
      export DO_CLEANUP="${
        if cfg.bootstrap.cleanUp
        then "true"
        else "false"
      }"
      exec /app/bootstrap.sh
    '';
  };
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
    adminPasswordFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the file containing the admin password.
      '';
    };
    jwtSecretFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to the file containing the JWT secret";
    };
    keySeedFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to the file containing the key seed";
    };
    bootstrap = {
      cleanUp = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to delete groups and users not specified in the config, also remove users from groups that they do not belong to
        '';
      };
      users = lib.mkOption {
        type = lib.types.listOf (
          lib.types.submodule {
            options = {
              id = lib.mkOption {
                type = lib.types.str;
                description = "ID of the user";
              };
              email = lib.mkOption {
                type = lib.types.str;
                description = "E-Mail of the user";
              };
              password_file = lib.mkOption {
                type = lib.types.nullOr lib.types.path;
                default = null;
                description = "Path to the file containing the user password";
              };
              displayName = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Display name of the user";
              };
              firstName = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "First name of the user";
              };
              lastName = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Last name of the user";
              };
              avatar_url = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Must be a valid URL to jpeg file. (ignored if `gravatar_avatar` specified)";
              };
              gravatar_avatar = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "the script will try to get an avatar from [gravatar](https://gravatar.com/) by previously specified email";
              };
              groups = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [];
                description = "An array of groups the user would be a member of (all the groups must be specified in the `group` option)";
              };
            };
          }
        );
        default = [];
        description = ''
          LLDAP users that will be provisioned at startup.

          See <https://github.com/lldap/lldap/blob/main/example_configs/bootstrap/bootstrap.md#user-config-file-example>
        '';
      };
      groups = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = ''
          Names of the groups that will be created.

          See <https://github.com/lldap/lldap/blob/main/example_configs/bootstrap/bootstrap.md#group-config-file-example>
        '';
      };
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
        Will be used as a default by other programs such as Authelia or PocketID when binding to LLDAP.
      '';
    };
    address = lib.mkOption {
      type = lib.types.str;
      default = "ldap://${name}:3890";
      readOnly = true;
      visible = false;
    };
    envFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to the environment file for LLDAP. Can be used to pass additional variables or secrets.
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

      # renovate: extractVersion=loose
      image = "ghcr.io/lldap/lldap:2025-07-29-alpine-rootless";
      user = config.tarow.podman.defaultUid;
      volumes =
        [
          "${storage}/db:/db"
          "${cfg.settings}:/data/lldap_config.toml"
        ]
        ++ (builtins.concatLists (map (s: s.volume) ((lib.attrValues userPasswordFiles) ++ [jwtSecret keySeedSecret adminPasswordSecret])))
        ++ finalUserVolumes
        ++ finalGroupVolumes
        ++ lib.optionals (finalUserVolumes != [] || finalUserVolumes != []) [
          "${bootstrapWrapper}:/app/bootstrap_wrapper.sh"
        ];

      extraConfig.Service.ExecStartPost =
        lib.mkIf (finalUserVolumes != [] || finalGroupVolumes != [])
        "${lib.getExe pkgs.podman} exec ${name} /app/bootstrap_wrapper.sh";

      environment = {LLDAP_KEY_FILE = "";} // jwtSecret.env // keySeedSecret.env // adminPasswordSecret.env;
      environmentFile = lib.optional (cfg.envFile != null) cfg.envFile;

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
