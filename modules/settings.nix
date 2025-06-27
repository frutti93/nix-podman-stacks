{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.tarow.podman;
in {
  imports = [./extension.nix];

  options.tarow.podman = {
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.podman;
    };
    enableSocket = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    socketLocation = lib.mkOption {
      type = lib.types.str;
      default = "/run/user/${toString cfg.hostUid}/podman/podman.sock";
      readOnly = true;
    };
    hostUid = lib.mkOption {
      type = lib.types.int;
      default = 1000;
    };
    defaultUid = lib.mkOption {
      type = lib.types.int;
      default = 0;
    };
    defaultGid = lib.mkOption {
      type = lib.types.int;
      default = 0;
    };
    defaultTz = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "Etc/UTC";
    };
    storageBaseDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/stacks";
    };
    externalStorageBaseDir = lib.mkOption {
      type = lib.types.str;
    };
    mediaStorageBaseDir = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.externalStorageBaseDir}/media";
    };
    hostIP4Address = lib.mkOption {
      type = lib.types.str;
      description = "The IPv4 address which will be used in case explicit bindings are required.";
    };
  };
  config = {
    services.podman = {
      enable = true;
      package = cfg.package;

      settings.containers.network.dns_bind_port = 1153;
    };

    systemd.user.sockets.podman = {
      Install.WantedBy = ["sockets.target"];
      Socket = {
        SocketMode = "0660";
        ListenStream = cfg.socketLocation;
      };
    };
    systemd.user.services.podman = {
      Install.WantedBy = ["default.target"];
      Service = {
        Delegate = true;
        Type = "exec";
        KillMode = "process";
        Environment = ["LOGGING=--log-level=info"];
        ExecStart = "${lib.getExe cfg.package} $LOGGING system service";
      };
    };
  };
}
