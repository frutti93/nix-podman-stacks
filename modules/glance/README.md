Highly customizable dashboard

- [Github](https://github.com/glanceapp/glance)

## Example

```nix
{config, ...}: {
  nps.stacks.glance = {
    enable = true;
    settings.pages.home = {
      columns.start = {
        rank = 500;
        size = "small";
        widgets = [
          {
            type = "server-stats";
            servers = [
              {
                type = "local";
                name = "Server";
              }
            ];
          }
          {
            type = "reddit";
            subreddit = "selfhosted";
            collapse-after = 3;
          }
        ];
      };
    };
  };
}
```

## Stack Options

<RenderDocs :options="data" :include="/nps\.stacks\.glance\.(?!containers($|\.)).*/" />

## Container Extension

Glance adds the `glance` container options to the existing `services.podman.containers.<name>` options.
Setting the `category` automatically adds the container to a `docker-containers` widget on the dashboard.

The `name` defaults to the container name, the `url` defaults to the URL registered in Traefik.
Additional settings (icon, description, href, ...) can be provided via freeform attributes, see <https://github.com/glanceapp/glance/blob/main/docs/configuration.md#docker-containers>.

Example:

```nix
{config, ...}: {
  nps.stacks.glance.enable = true;

  nps.stacks.streaming.containers.jellyfin.glance = {
    category = "Media";
    name = "Jellyfin";
    description = "Media Server";
    icon = "si:jellyfin";
  };
}
```

<RenderDocs :options="data" :include="/services\.podman\.containers\..+\.glance(\..*)?/" />

## Container Aliases

<RenderDocs :options="data" :include="/nps\.stacks\.glance\.containers\..*/" />
