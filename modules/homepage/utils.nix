lib: let
  isPathValue = v: v ? "path";

  mkEnvNameFromPath = pathComponents:
    "HOMEPAGE_FILE_${lib.toUpper (lib.concatStringsSep "_" pathComponents)}"
    |> lib.strings.sanitizeDerivationName
    |> lib.replaceStrings ["-"] ["_"];

  replacePathsDeep = attrs: let
    recurse = path: v:
      if isPathValue v
      then ''{{${mkEnvNameFromPath path}}}''
      else if lib.isAttrs v
      then lib.mapAttrs (k: v2: recurse (path ++ [k]) v2) v
      else if builtins.isList v
      then map (v2: recurse path v2) v
      else v;
  in
    recurse [] attrs;

  extractPathEntries = attrs: let
    recurse = path: v:
      if isPathValue v
      then [
        {
          name = mkEnvNameFromPath path;
          value = v.path;
        }
      ]
      else if lib.isAttrs v
      then lib.mapAttrsToList (k: v2: recurse (path ++ [k]) v2) v |> lib.flatten
      else if builtins.isList v
      then map (v2: recurse path v2) v |> lib.flatten
      else [];
  in
    recurse [] attrs;

  pathEntries = attrs:
    attrs
    |> extractPathEntries
    |> lib.flatten
    |> lib.listToAttrs;
in {
  inherit isPathValue mkEnvNameFromPath replacePathsDeep extractPathEntries pathEntries;
}
