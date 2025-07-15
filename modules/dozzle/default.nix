{
  config,
  lib,
  ...
}: let
  name = "dozzle";
  cfg = config.tarow.podman.stacks.${name};
in {
  imports = [./extension.nix] ++ import ../mkAliases.nix config lib name [name];

  options.tarow.podman.stacks.${name}.enable =
    lib.mkEnableOption name
    // {
      description = ''
        Whether to enable Dozzle.
        The module contains an extension that will automatically add all containers to Dozzle groups,
        if they `stack` attribute is set.
      '';
    };

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "docker.io/amir20/dozzle:latest";
      volumes = [
        "${config.tarow.podman.socketLocation}:/var/run/docker.sock:ro"
      ];
      port = 8080;
      traefik.name = name;
      homepage = {
        category = "Monitoring";
        name = "Dozzle";
        settings = {
          description = "Container Log Viewer";
          icon = "dozzle";
        };
      };
    };
  };
}
