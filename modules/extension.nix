{
  pkgs,
  lib,
  config,
  ...
}:
let
  globalConf = config;
  mkSocketName =
    {
      name,
      port,
      prefix ? "podman-",
      suffix ? ".socket",
    }:
    "${prefix}${name}-${toString port |> lib.replaceStrings [ "." ":" ] [ "_" "-" ]}${suffix}";
in
{
  # Extend the podman options in order to custom build custom abstraction
  options.services.podman.containers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        {
          name,
          config,
          ...
        }:
        {
          options = with lib; {
            dependsOn = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = ''
                List of systemd resources that this container depends on.
                When specifying a dependency on another container, use the option `dependsOnContainer` instead.
              '';
            };

            dependsOnContainer = mkOption {
              type = types.listOf types.str;
              default = [ ];
              apply = map (d: "podman-${d}.service");
              description = ''
                List of containers that this container depends on.
                Similar to `dependsOn`, but will automatically apply correct pre- and suffix for
                the generated systemd services.
              '';
            };

            fileEnvMount = lib.mkOption {
              type = lib.types.attrsOf (
                lib.types.oneOf [
                  lib.types.path
                  (lib.types.submodule {
                    options = {
                      sourcePath = mkOption {
                        type = lib.types.str;
                        description = "Source path on host.";
                      };
                      destPath = mkOption {
                        type = lib.types.str;
                      };
                    };
                  })
                ]
              );
              apply = lib.mapAttrs (
                name: value:
                if builtins.isAttrs value then
                  value
                else
                  {
                    srcPath = value;
                    dstPath = "/run/secrets/${name}";
                  }

              );
              default = { };
              example = {
                # Short form: just give the source path, destPath is inferred
                DB_PASSWORD_FILE = ./secrets/db-password.txt;

                # Long form: explicitly set sourcePath and destPath
                API_KEY_FILE = {
                  sourcePath = "/secrets/api-key.txt";
                  destPath = "/app/config/api-key.txt";
                };
              };
              description = ''
                Convenience wrapper option, that simplifies passing `_FILE` based environment variables.
                For each attribute in the attrset, a volume mapping from `sourcePath` to `destPath` will be added,
                and an environment variable will be set to the `destPath`.

                Example:
                ```nix
                API_KEY_FILE = {
                  srcPath = "/host/api-key.txt";
                  dstPath = "/container/api-key.txt";
                };
                ```
                will add a volume to the container, e.g.:
                ```nix
                volumes = [''${sourcePath}:''${destPath}];
                ```
                and also add an environment variable:
                ```nix
                env.API_KEY_FILE = destPath;
                ```

                You can also provide a simple path, which will be treated as the `sourcePath`:
                ```nix
                DB_PASSWORD_FILE = ./secrets/db-password.txt;
                ```
                The `destPath` will be inferred.
              '';
            };

            socketActivation = mkOption {
              type = types.listOf (
                types.submodule {
                  options = {
                    port = mkOption {
                      type = types.oneOf [
                        types.str
                        types.port
                      ];
                      description = "Port that the socket should listen on";
                    };
                    fileDescriptorName = mkOption {
                      type = types.nullOr types.str;
                      default = null;
                      description = ''
                        Name of the file descriptor that the socket should use.
                      '';
                    };
                  };
                }
              );
              default = [ ];
              description = ''
                List of socket activation configurations for this container.
                Each entry should specify a port and optionally a file descriptor name.
                This will create a systemd socket that activates the container when accessed.

                Will be used by containers like Traefik by default. Allows the container to access real-ip
                without the request being proxied through pasta/slirp4netns.

                For details regarding rootless Podman networking and socket activation,
                see: <https://github.com/eriksjolund/podman-networking-docs>
              '';
            };

            stack = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = ''
                Stack that a container is part of.
                For every stack, a Podman networking will be crearted that the respective container will be connected to.
              '';
            };
          };

          config = {
            autoUpdate = lib.mkDefault "registry";

            network = lib.mkIf (config.stack != null) [ config.stack ];
            dependsOn =
              (map (
                sa:
                mkSocketName {
                  inherit name;
                  port = sa.port;
                }
              ) config.socketActivation)
              ++ lib.optional (builtins.any (lib.hasPrefix "${globalConf.tarow.podman.socketLocation}:") config.volumes) "podman.socket";

            environment = {
              TZ = lib.mkDefault globalConf.tarow.podman.defaultTz;
            }
            // lib.mapAttrs (_: v: v.destPath) config.fileEnvMount;

            volumes = config.fileEnvMount |> lib.attrValues |> lib.map (v: "${v.sourcePath}:${v.destPath}");

            extraConfig = {
              Unit.Requires = config.dependsOn ++ config.dependsOnContainer;
              Unit.After = config.dependsOn ++ config.dependsOnContainer;

              # Automatically create host directories for volumes if they don't exist
              Service.ExecStartPre =
                let
                  volumes = map (v: lib.head (lib.splitString ":" v)) (config.volumes or [ ]);
                  volumeDirs = lib.filter (v: lib.hasInfix "/" v && !lib.hasPrefix "/run" v) volumes;
                in
                "${lib.getExe (
                  pkgs.writeShellApplication {
                    name = "setupVolumes";
                    runtimeInputs = [ pkgs.coreutils ];
                    text = (map (v: "[ -e ${v} ] || mkdir -p ${v}") volumeDirs) |> lib.concatStringsSep "\n";
                  }
                )}";
            };
          };
        }
      )
    );
  };

  config = {
    # For every stack, define a default network.
    services.podman.networks =
      let
        stacks =
          config.services.podman.containers
          |> builtins.attrValues
          |> builtins.filter (c: c.stack != null)
          |> builtins.map (c: c.stack);
      in
      lib.genAttrs stacks (s: lib.mkDefault { driver = "bridge"; });

    # Create sockets for socketActivated containers
    systemd.user.sockets =
      let
        containers = lib.filterAttrs (n: v: v.socketActivation != [ ]) config.services.podman.containers;
        mkSockets =
          name: container:
          map (
            sa:
            lib.nameValuePair
              (mkSocketName {
                inherit name;
                port = sa.port;
                suffix = "";
              })
              {
                Socket.ListenStream = "${toString sa.port}";
                Socket.ListenDatagram = "${toString sa.port}";
                Socket.Service = "podman-${name}.service";
                Socket.FileDescriptorName = lib.mkIf (sa.fileDescriptorName != null) sa.fileDescriptorName;
                Install.WantedBy = [ "sockets.target" ];
              }
          ) container.socketActivation;
        sockets = (lib.mapAttrsToList mkSockets containers) |> lib.flatten |> lib.listToAttrs;
      in
      sockets;
  };
}
