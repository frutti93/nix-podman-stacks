{
  lib,
  config,
  ...
}: let
  stackCfg = config.tarow.podman.stacks.traefik;

  ip4Address = config.tarow.podman.hostIP4Address;

  getPort = port: index:
    if port == null
    then null
    else if (builtins.isInt port)
    then builtins.toString port
    else builtins.elemAt (builtins.match "([0-9]+):([0-9]+)" port) index;
in {
  options.services.podman.containers = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule ({
      name,
      config,
      ...
    }: let
      traefikCfg = config.traefik;
      port = config.port;

      fullHost =
        if (traefikCfg.subDomain == "")
        then stackCfg.domain
        else "${traefikCfg.subDomain}.${stackCfg.domain}";
    in {
      options = with lib; {
        # Main port that will be used by traefik. If traefik is disabled, it will be added to the "ports" section
        port = mkOption {
          type = types.nullOr (types.oneOf [types.str types.int]);
          default = null;
        };
        traefik = with lib; {
          name = mkOption {
            type = types.nullOr types.str;
            default = null;
          };
          subDomain = mkOption {
            type = types.str;
            apply = lib.trim;
            default =
              if traefikCfg.name != null
              then traefikCfg.name
              else "";
          };
          serviceHost = mkOption {
            type = lib.types.str;
            default = let
              hostPort = getPort port 0;
              ipHost =
                if hostPort == null
                then "${ip4Address}"
                else "${ip4Address}:${hostPort}";

              fullHost =
                if (stackCfg.enable)
                then
                  (
                    if (traefikCfg.subDomain == "")
                    then stackCfg.domain
                    else "${traefikCfg.subDomain}.${stackCfg.domain}"
                  )
                else ipHost;
            in
              fullHost;
            readOnly = true;
            apply = d: let
              hostPort = getPort port 0;
            in
              if stackCfg.enable
              then d
              else if hostPort == null
              then "${ip4Address}"
              else "${ip4Address}:${hostPort}";
          };
          serviceDomain = mkOption {
            type = lib.types.str;
            default = traefikCfg.serviceHost;
            readOnly = true;
            apply = d:
              if stackCfg.enable
              then "https://${d}"
              else "http://${d}";
          };
          middlewares = mkOption {
            type = types.listOf (types.enum (lib.attrNames stackCfg.dynamicConfig.http.middlewares or {}));
            default = ["private"];
          };
        };
      };

      config = let
        enableTraefik = stackCfg.enable && traefikCfg.name != null;
        hostPort = getPort port 0;
        containerPort = getPort port 1;
      in {
        labels = lib.optionalAttrs enableTraefik ({
            "traefik.enable" = "true";
            "traefik.http.routers.${name}.rule" = ''Host(\`${traefikCfg.serviceHost}\`)'';
            # "traefik.http.routers.${name}.entrypoints" = "websecure,websecure-internal";
            "traefik.http.routers.${name}.service" = lib.mkDefault name;
          }
          // lib.optionalAttrs (containerPort != null) {
            "traefik.http.services.${name}.loadbalancer.server.port" = containerPort;
          }
          // {
            "traefik.http.routers.${name}.middlewares" = builtins.concatStringsSep "," (map (m: "${m}@file") traefikCfg.middlewares);
          });
        network = lib.mkIf enableTraefik [stackCfg.network];
        ports = lib.optional (!enableTraefik && (port != null)) "${hostPort}:${containerPort}";
      };
    }));
  };
}
