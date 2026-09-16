Dynamic DNS client specifically designed to work with Cloudflare

- [Github](https://github.com/Tarow/dockdns)

## Example

```nix
{config, ...}: {
  nps.stacks.dockdns = {
    enable = true;

    # Cloudflare API-Token for domain "example.com"
    extraEnv.EXAMPLE_COM_API_TOKEN.fromFile = config.sops.secrets."dockdns/cf_api_token".path;
    settings.domains = [
      {
        # Setup Dyn-DNS for one endpoint
        name = "vpn.example.com";
      }
    ];
  };
}
```

## Stack Options

<RenderDocs :options="data" :include="/nps\.stacks\.dockdns\.(?!containers($|\.)).*/" />

## Container Extension

If Traefik & DockDNS are enabled, every exposed container will automatically get a `dockdns.name=<traefikHost>` label.
This will make DockDNS automatically create DNS records for exposed containers - and also remove them once the serivce is private again.

Also see the [`expose`](/container-options#services.podman.containers.<name>.expose) container option.

## Container Aliases

<RenderDocs :options="data" :include="/nps\.stacks\.dockdns.containers\..*/" />
