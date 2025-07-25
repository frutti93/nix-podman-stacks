stack: containers: {
  config,
  lib,
  ...
}: let
  cfg = config.tarow.podman.stacks.${stack};
  socketProxyCfg = config.tarow.podman.stacks.docker-socket-proxy;
  socketProxyAssertion = !cfg.useSocketProxy || socketProxyCfg.enable;
  useSocketProxy = cfg.useSocketProxy && socketProxyAssertion;
in {
  options.tarow.podman.stacks.${stack} = {
    useSocketProxy = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to use the Docker Socket Proxy for this stack.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.useSocketProxy || socketProxyCfg.enable;
        message = "The option 'tarow.podman.stacks.${stack}.useSocketProxy' is set to true, but the 'docker-socket-proxy' stack is not enabled.";
      }
    ];

    services.podman.containers =
      lib.mkIf useSocketProxy
      ((lib.flatten containers)
        |> map (name:
          lib.nameValuePair name {
            dependsOnContainer = ["docker-socket-proxy"];
          })
        |> lib.listToAttrs);
  };
}
