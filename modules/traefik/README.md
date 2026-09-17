Modern HTTP reverse proxy

- [Github](https://github.com/traefik/traefik)
- [Website](https://traefik.io/)

## Examples

### Simple (Cloudflare)

```nix
{config, ...}: {
  nps.stacks.traefik = {
    enable = true;

    domain = "example.com";
    # Token will be used to fetch Letsencrypt wildcard certificates automatically (DNS challenge)
    extraEnv = {
      CF_DNS_API_TOKEN.fromFile = config.sops.secrets."traefik/cf_api_token".path;
    };
  };
}
```

### With different DNS provider

```nix
{config, ...}: {
  nps.stacks.traefik = {
    enable = true;

    domain = "example.com";
    staticConfig.certificatesResolvers.letsencrypt.acme.dnsChallenge.provider = "porkbun";
    extraEnv = {
      PORKBUN_API_KEY.fromFile = config.sops.secrets."traefik/porkbun_api_key".path;
      PORKBUN_SECRET_API_KEY.fromFile = config.sops.secrets."traefik/porkbun_secret_api_key".path;
    };
  };
}
```

### With Geoblock

```nix
{config, ...}: {
  nps.stacks.traefik = {
    enable = true;

    domain = "example.com";
    extraEnv.CF_DNS_API_TOKEN.fromFile = config.sops.secrets."traefik/cf_api_token".path;

    # For exposed services, we can limit access to certain countries using a geoblock middleware
    geoblock.allowedCountries = ["DE"];
  };
}
```

### With file provider

```nix
{config, ...}: {
  nps.stacks.traefik = {
    enable = true;

    domain = "example.com";
    extraEnv.CF_DNS_API_TOKEN.fromFile = config.sops.secrets."traefik/cf_api_token".path;
    provider = "file";
  };
}
```

## Stack Options

<RenderDocs :options="data" :include="/nps\.stacks\.traefik\.(?!containers($|\.)).*/" />

## Container Extension

Traefik adds several container options to the existing `services.podman.containers.<name>` options:

- `port`: The main port that Traefik will forward traffic to.
- `expose`: Whether the service should be publicly reachable. When `false` (default), the `private` middleware is applied, which only allows requests from private CIDR ranges. When `true`, the `public` middleware is applied, which allows access from the internet (with rate limit, security headers and optional geoblock/Crowdsec).
- `traefik`: Controls how the service is registered in Traefik (`name`, `subDomain`, `middleware`). The service is only registered when `traefik.name` is set.

Example:

```nix
{config, ...}: {
  nps.stacks.streaming.containers.jellyfin = {
    expose = true;

    traefik = {
      subDomain = "movies";
    };
  };
}
```

<RenderDocs :options="data" :include="/services\.podman\.containers\..+\.(port|expose|traefik)(\..*)?/" />

## Container Aliases

<RenderDocs :options="data" :include="/nps\.stacks\.traefik\.containers\..*/" />
