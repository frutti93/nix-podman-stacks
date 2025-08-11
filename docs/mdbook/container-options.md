# Container Options

This project extends Home Managers existing [`services.podman.containers`](https://home-manager-options.extranix.com/?query=services.podman.containers&release=master) options, to provide additional abstractions for example for Traefik or Homepage.

The options can be set directly on `services.podman.container` level, or through the stack aliases provided with this project.
For example, the following two configurations are equivalent:

```nix
nps.stacks = {
    streaming.containers.jellyfin.traefik.middlewares = ["public"];
};
```

```nix
services.podman.containers.jellyfin.traefik.middlewares = ["public"];
```

The following lists all extension options that will be added by this project.

<br/><br/>

---
