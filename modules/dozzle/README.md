Lightweight, real-time log viewer for containers

- [Github](https://github.com/amir20/dozzle)
- [Website](https://dozzle.dev/)

## Example

```nix
{
  nps.stacks.dozzle.enable = true;
}
```

## Stack Options

<RenderDocs :options="data" :include="/nps\.stacks\.dozzle\.(?!containers($|\.)).*/" />

## Container Extension

If Dozzle is enabled, all containers that are part of a stack (i.e. have their `stack` attribute set)
are automatically grouped in Dozzle. The container gets a `dev.dozzle.group` label with the stack name,
so the logs of all containers of a stack can be filtered by that group.

## Container Aliases

<RenderDocs :options="data" :include="/nps\.stacks\.dozzle\.containers\..*/" />
