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
        self.homeModules.all
        {
          home.stateVersion = "25.05";
          home.username = "someuser";
          home.homeDirectory = "/home/someuser";
          tarow.podman = {
            hostIP4Address = "10.10.10.10";
            hostUid = 1000;
            externalStorageBaseDir = "/mnt/ext";
          };
        }
      ];
    };
  in
    pkgs.nixosOptionsDoc {
      inherit (eval) options;

      documentType = "none";
      warningsAreErrors = false;

      transformOptions = option:
        option
        // {
          visible =
            option.visible
            && (builtins.elem "tarow" option.loc);
        };
    };
}
