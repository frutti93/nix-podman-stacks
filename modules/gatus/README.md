Health dashboard for containers

- [Github](https://github.com/TwiN/gatus)

## Example

```nix
{config, ...}: {
  nps.stacks.gatus = {
    enable = true;

    db = {
      type = "postgres";
      passwordFile = config.sops.secrets."gatus/postgresPassword".path;
    };

    settings.endpoints = [
      {
        name = "Some website";
        url = "https://example.com";
        client.dns-resolver = "tcp://1.1.1.1:53";
        conditions = [
          "[STATUS] == 200"
        ];
      }
    ];

    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."gatus/authelia_client_secret".path;
      clientSecretHash = "$pbkdf2-sha512$...";
    };
  };
}
```

## Stack Options

<RenderDocs :options="data" :include="/nps\.stacks\.gatus\.(?!containers($|\.)).*/" />

## Container Extension

Gatus adds the `gatus` container options to the existing `services.podman.containers.<name>` options.
Enabling it adds the container's service to the Gatus endpoint configuration, using the URL registered in Traefik and the default endpoint settings (`nps.stacks.gatus.defaultEndpoint`).

Individual settings (e.g. `url` or `conditions`) can be overridden via the `settings` attribute, see <https://github.com/TwiN/gatus?tab=readme-ov-file#endpoints>.

Example:

```nix
{config, ...}: {
  nps.stacks.gatus.enable = true;

  nps.stacks.blocky.containers.blocky = {
    gatus = {
      enable = true;
      settings = {
        url = "host.containers.internal";
        dns = {
          query-name = config.nps.stacks.traefik.domain;
          query-type = "A";
        };
        conditions = [
          "[DNS_RCODE] == NOERROR"
        ];
      };
    };
  };
}

```

<RenderDocs :options="data" :include="/services\.podman\.containers\..+\.gatus(\..*)?/" />

## Container Aliases

<RenderDocs :options="data" :include="/nps\.stacks\.gatus\.containers\..*/" />
