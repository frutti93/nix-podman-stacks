{
  config,
  lib,
  ...
}: let
  name = "ittools";
  cfg = config.tarow.podman.stacks.${name};
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.tarow.podman.stacks.${name}.enable = lib.mkEnableOption name;

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "ghcr.io/corentinth/it-tools:2024.5.13-a0bc346";

      port = 80;
      traefik.name = name;
      homepage = {
        category = "General";
        name = "IT-Tools";
        settings = {
          description = "Developer Tools";
          icon = "it-tools";
        };
      };
    };
  };
}
