config: lib: stackName: containers:
map (
  c: (lib.doRename {
    from = ["tarow" "podman" "stacks" stackName "containers" c];
    to = ["services" "podman" "containers" c];
    use = x: x;
    warn = false;
    visible = true;
    condition = config.tarow.podman.stacks.${stackName}.enable;
  })
)
containers
