{
  config,
  lib,
  ...
}: let
  name = "omnitools";
  cfg = config.tarow.podman.stacks.${name};
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.tarow.podman.stacks.${name}.enable = lib.mkEnableOption name;

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "docker.io/iib0011/omni-tools:latest";

      port = 80;
      traefik.name = name;
      homepage = {
        category = "General";
        name = "OmniTools";
        settings = {
          description = "Tool Collection";
          icon = "omni-tools";
        };
      };
    };
  };
}
