Customizable application dashboard

- [Github](https://github.com/gethomepage/homepage)
- [Website](https://gethomepage.dev/)

## Example

```nix
{
  nps.stacks.homepage = {
    enable = true;

    containers.homepage.volumes = [
      "/hostpath/to/image:/app/public/images/background.jpg"
    ];
    settings.background = {
      image = "/images/background.jpg";
      opacity = 50;
    };
    widgets = [
      {
        openweathermap = {
          units = "metric";
          cache = 5;
          apiKey.path = config.sops.secrets."OPENWEATHERMAP_API_KEY".path;
        };
      }
    ];
  };
}
```

## Stack Options

<RenderDocs :options="data" :include="/nps\.stacks\.homepage\.(?!containers($|\.)).*/" />

## Container Extension

Homepage adds the `homepage` container options to the existing `services.podman.containers.<name>` options.
Setting the `category` automatically adds the container to the Homepage dashboard under that category.

The `name` defaults to the container name, the service `href` is automatically set to the URL registered in Traefik.
Additional settings (icon, description, widget configuration, ...) can be provided via the `settings` attribute, see <https://gethomepage.dev/configs/services/>.

To hide a service from the dashboard, set the `category` option to `null`.

Example:

```nix
{config, ...}: {
  nps.stacks.homepage.enable = true;

  nps.stacks.streaming.containers.jellyfin.homepage = {
    category = "Media";
    name = "Jellyfin";
    settings = {
      description = "Media Server";
      icon = "jellyfin";
    };
  };
}
```

<RenderDocs :options="data" :include="/services\.podman\.containers\..+\.homepage(\..*)?/" />

## Container Aliases

<RenderDocs :options="data" :include="/nps\.stacks\.homepage\.containers\..*/" />
