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
    in {
      options = with lib; {
        port = mkOption {
          type = types.nullOr (types.oneOf [types.str types.int]);
          default = null;
          description = ''
            Main port that Traefik will forward traffic to.
            If Traefik is disabled, it will instead be added to the "ports" section
          '';
        };
        traefik = with lib; {
          name = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              The name of the service as it will be registered in Traefik.
              Will be used as a default for the subdomain.

              If not set (null), the service will not be registered in Traefik.
            '';
          };
          subDomain = mkOption {
            type = types.str;
            description = ''
              The subdomain of the service as it will be registered in Traefik.
            '';
            apply = lib.trim;
            default =
              if traefikCfg.name != null
              then traefikCfg.name
              else "";
            defaultText = "traefikCfg.name";
          };
          serviceAddressInternal = mkOption {
            type = lib.types.str;
            default = "${name}:${getPort port 1}";
            defaultText = lib.literalExpression ''"''${containerName}''${containerCfg.port}"'';
            description = ''
              The internal main address of the service. Can be used for internal communication
              without going through Traefik, when inside the same Podman network.
            '';
            readOnly = true;
          };
          serviceHost = mkOption {
            type = lib.types.str;
            description = ''
              The host name of the service as it will be registered in Traefik.
            '';
            defaultText = lib.literalExpression ''"''${traefikCfg.subDomain}.''${tarow.podman.stacks.traefik.domain}"'';
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
            description = ''
              The full domain of the service as it will be registered in Traefik.
              This will be the serviceHost including the "https://" prefix.
            '';
            default = traefikCfg.serviceHost;
            defaultText = lib.literalExpression ''"https://''${traefikCfg.serviceHost}"'';
            readOnly = true;
            apply = d:
              if stackCfg.enable
              then "https://${d}"
              else "http://${d}";
          };
          middlewares = mkOption {
            type = types.listOf (types.enum (lib.attrNames stackCfg.dynamicConfig.http.middlewares or {}));
            default = ["private"];
            description = ''
              A list of middlewares to apply to the service.
              These will be applied in the order they are listed.
            '';
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
