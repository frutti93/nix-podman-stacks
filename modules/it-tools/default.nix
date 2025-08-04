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
      # renovate: versioning=regex:^(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)-(?<build>.+)$
      image = "ghcr.io/corentinth/it-tools:2024.10.22-7ca5933";

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
