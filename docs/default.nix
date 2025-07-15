{
  self,
  pkgs,
  inputs,
  lib,
  ...
}: let
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
  gitHubDeclaration = user: repo: branch: subpath: {
    url = "https://github.com/${user}/${repo}/blob/${branch}/${subpath}";
    name = "<${repo}/${subpath}>";
  };

  nixPodmanStacksPath = toString self;
  hmPath = toString inputs.home-manager;

  hasLocPrefix = prefix: loc: lib.lists.take (lib.length prefix) loc == prefix;

  mkOptionsDoc = prefix:
    pkgs.nixosOptionsDoc {
      inherit (eval) options;

      documentType = "none";
      warningsAreErrors = false;

      transformOptions = option:
        option
        // {
          visible =
            option.visible
            && option.loc != ["services" "podman" "containers"]
            && (lib.hasPrefix nixPodmanStacksPath (toString option.declarations))
            && hasLocPrefix prefix option.loc;
        }
        // {
          declarations =
            map (
              decl:
                if lib.hasPrefix nixPodmanStacksPath (toString decl)
                then
                  gitHubDeclaration "tarow" "nix-podman-stacks" "main" (
                    lib.removePrefix "/" (lib.removePrefix nixPodmanStacksPath (toString decl))
                  )
                else if lib.hasPrefix hmPath (toString decl)
                then
                  gitHubDeclaration "nix-community" "home-manager" "master" (
                    lib.removePrefix "/" (lib.removePrefix hmPath (toString decl))
                  )
                else null
            )
            option.declarations
            |> lib.filter (d: d != null);
        };
    };

  # Partitino into settings and stack options

  opts =
    mkOptionsDoc ["tarow" "podman"]
    |> builtins.partition (
      opt: lib.hasLocPrefix ["services" "podman" "stacks"] opt.loc
    );
  settingsOptions = opts.wrong;
  stackOptions = opts.right;

  containerOptions = mkOptionsDoc ["services" "podman"];
in {
  book = pkgs.stdenv.mkDerivation {
    pname = "nix-podman-stacks-docs-book";
    version = "0.0.1";
    src = self;

    nativeBuildInputs = [
      pkgs.mdbook
    ];

    dontConfigure = true;
    dontFixup = true;

    buildPhase = ''
      runHook preBuild
      mkdir -p src

      cp docs/mdbook/* src/
      cat ${stackOptions.optionsCommonMark} >> src/stack-options.md
      cat ${containerOptions.optionsCommonMark} >> src/container-options.md
      mdbook build
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mv book $out
      runHook postInstall
    '';
  };
}
