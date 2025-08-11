# Stack Options

The `nps.stacks` options allow enabling and configuring various stacks.
Most stacks just require the `enable` option set to `true`. Some stacks can optionally be configured to adjust settings or pass environment files (e.g. for secrets).

If you want to make changes that are not possible through the exposed stack options directly, aliases to the `services.podman.container` options are provided, which let you override or modify any attribute that the stack modules set.

For instance, accessing `nps.stacks.streaming.containers.jellyfin` is an alias to `services.podman.containers.jellyfin` and allows editing any of the known [`services.podman.containers`](https://home-manager-options.extranix.com/?query=services.podman.containers&release=master) options, such as networks, volumes and environment files. Usually this should not be necessary though.

The following list contains the options for all available stacks.
<br/><br/>

---
