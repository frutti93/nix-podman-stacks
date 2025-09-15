config: lib: stackName: containers:
lib.flatten containers
|> (map (c: [
  (lib.doRename {
    from = [
      "nps"
      "stacks"
      stackName
      "containers"
      c
    ];
    to = [
      "services"
      "podman"
      "containers"
      c
    ];
    use = x: x;
    warn = false;
    visible = true;
    condition = config.nps.stacks.${stackName}.enable && (config.nps.stacks.${stackName}.${c}.enable or true);
  })
  (lib.doRename {
    from = [
      "nps"
      "containers"
      c
    ];
    to = [
      "services"
      "podman"
      "containers"
      c
    ];
    use = x: x;
    warn = false;
    visible = true;
    condition = config.nps.stacks.${stackName}.enable && (config.nps.stacks.${stackName}.${c}.enable or true);
  })
]))
|> lib.flatten
