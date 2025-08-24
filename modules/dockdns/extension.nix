{
  lib,
  config,
  ...
}: let
  dockdnsEnabled = config.nps.stacks.dockdns.enable;
  traefikEnabled = config.nps.stacks.traefik.enable;
in {
  # If a container has the public middleware, create a record for it
  options.services.podman.containers = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule ({config, ...}: {
      config = let
        traefikCfg = config.traefik;
        isPublic = traefikCfg.middleware.public.enable or false;
      in
        lib.mkIf (dockdnsEnabled && traefikEnabled && isPublic) {
          labels."dockdns.name" = traefikCfg.serviceHost;
        };
    }));
  };
}
