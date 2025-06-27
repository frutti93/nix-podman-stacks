lib: stackName: containers:
containers
|> map (
  n:
    lib.mkAliasOptionModule
    ["tarow" "podman" "stacks" stackName "containers" n]
    ["services" "podman" "containers" n]
)
