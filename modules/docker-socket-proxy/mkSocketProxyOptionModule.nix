{
  stack,
  container ? stack,
  targetLocation ? "/var/run/docker.sock",
}: {
  config,
  lib,
  ...
}: let
  cfg = config.tarow.podman.stacks.${stack};
  socketProxyCfg = config.tarow.podman.stacks.docker-socket-proxy;
in {
  options.tarow.podman.stacks.${stack} = {
    useSocketProxy = lib.mkOption {
      type = lib.types.bool;
      default = config.tarow.podman.stacks.docker-socket-proxy.enable;
      defaultText = lib.literalExpression ''config.tarow.podman.stacks.docker-socket-proxy.enable'';
      description = ''
        Whether to use the Socket Proxy for the ${stack} stack.
        Will be enabled by default if the 'docker-socket-proxy' stack is enabled.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.useSocketProxy || socketProxyCfg.enable;
        message = "The option 'tarow.podman.stacks.${stack}.useSocketProxy' is set to true, but the 'docker-socket-proxy' stack is not enabled.";
      }
    ];

    services.podman.containers = (
      lib.flatten container
      |> map (name:
        lib.nameValuePair name {
          # Socket Proxy option exists, but it not used.
          # Mount the socket as a volume directly then.
          volumes = lib.mkIf (!cfg.useSocketProxy) [
            "${config.tarow.podman.socketLocation}:/${targetLocation}:ro"
          ];

          # Socket Proxy option is set, add systemd dependency to socket-proxy service
          dependsOnContainer = lib.mkIf cfg.useSocketProxy ["docker-socket-proxy"];
        })
      |> lib.listToAttrs
    );
  };
}
