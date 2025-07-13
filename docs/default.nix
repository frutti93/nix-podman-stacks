{
  self,
  pkgs,
  inputs,
  lib,
  ...
}: {
  docs = let
    # Use a full HM system rather than (say) the result of
    # `lib.evalModules`.  This is because our HM module refers to
    # `services.podman`, which may itself refer to any number of other NixOS
    # options, which may themselves... etc.  Without this, then, we'd get an
    # evaluation error generating documentation.
    eval = inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        self.nix-podman-stacks.homeModules.all
        {
          home.stateVersion = "25.05";
          home.username = "someuser";
          home.homeDirectory = "/home/someuser";
        }
      ];
    };
  in
    pkgs.nixosOptionsDoc {
      inherit (eval) options;

      # Default is currently "appendix".
      documentType = "none";

      # Only include our own options.
      transformOptions = let
        ourPrefix = "${toString self}/";
        nixosModules = "nix/nixos-modules.nix";
        link = {
          url = "/${nixosModules}";
          name = nixosModules;
        };
      in
        opt:
          opt
          // {
            visible = opt.visible && (lib.any (lib.hasPrefix ourPrefix) opt.declarations);
            declarations = map (decl:
              if lib.hasPrefix ourPrefix decl
              then link
              else decl)
            opt.declarations;
          };
    };
}
