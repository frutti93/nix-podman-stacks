{
  config,
  lib,
  ...
}: let
  forwardAuthContainers =
    lib.filterAttrs (k: c: c.forwardAuth.enable && c.forwardAuth.rules != [])
    config.services.podman.containers;
  forwardAuthRules = lib.mapAttrs (name: c: c.forwardAuth.rules) forwardAuthContainers |> lib.attrValues;
in {
  config = lib.mkIf (forwardAuthContainers != {}) {
    nps.stacks.authelia.settings.access_control.rules = lib.mkMerge forwardAuthRules;
  };

  options.services.podman.containers = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule ({
      name,
      config,
      ...
    }: {
      config.traefik.middlewares = lib.mkIf config.forwardAuth.enable ["authelia"];
      options.forwardAuth = with lib; {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Whether to enable forward auth. This will enable the 'authelia' Traefik middleware for this container.
            Every request will be forwarded to be authorized by Authelia first.

            Optionally, access control rules for this container can be specified in the settings.
            They will be added to the Authelia settings.

            See <https://www.authelia.com/configuration/security/access-control/>
          '';
        };
        rules = mkOption {
          type = with types;
            listOf (submodule {
              options = {
                domain = mkOption {
                  type = listOf str;
                  default = [config.traefik.serviceHost];
                  defaultText = lib.literalExpression ''[ containerCfg.traefik.serviceUrl ]'';
                  description = ''
                    Domain(s) that will be matched for the rule. Defaults to the servie domain registered in Traefik.
                    Either this, or the `domain_regex` options has to be set.

                    See <https://www.authelia.com/configuration/security/access-control/#domain>
                  '';
                };
                domain_regex = mkOption {
                  type = listOf str;
                  default = [];
                  description = ''
                    Regex(es) criteria matching the domain. Defaults to the servie domain registered in Traefik.
                    Has to be set if the domain is unset.

                    See <https://www.authelia.com/configuration/security/access-control/#domain_regex>
                  '';
                };
                policy = mkOption {
                  type = enum ["" "deny" "bypass" "one_factor" "two_factor"];
                  default = "";
                  description = ''
                    The specific policy to apply to the selected rule.
                    This is not criteria for a match, this is the action to take when a match is made.

                    See <https://www.authelia.com/configuration/security/access-control/#policy>
                  '';
                };
              };
            });
          default = [];
          description = ''
            Rules matching a request. When all criteria of a rule match the request, the defined `policy` is applied.

            See <https://www.authelia.com/configuration/security/access-control/#rules>
          '';
        };
      };
    }));
  };
}
