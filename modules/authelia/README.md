SSO and OIDC provider

- [Github](https://github.com/authelia/authelia)
- [Website](https://www.authelia.com/)

---

> [!NOTE]
> If you have access_control rules configured, (e.g. when using forwardAuth), it is recommended to change the `default_policy` to `deny`:
>
> ```nix
> nps.stacks.authelia.settings.access_control.default_policy = "deny";
> ```

## Example

```nix
{config, ...}: {
  nps.stacks.authelia = {
    enable = true;
    jwtSecretFile = config.sops.secrets."authelia/jwt_secret".path;
    sessionSecretFile = config.sops.secrets."authelia/session_secret".path;
    storageEncryptionKeyFile = config.sops.secrets."authelia/encryption_key".path;
    oidc = {
      enable = true;
      hmacSecretFile = config.sops.secrets."authelia/oidc_hmac_secret".path;
      jwksRsaKeyFile = config.sops.secrets."authelia/oidc_rsa_pk".path;
    };
    sessionProvider = "redis";
  };
}
```

## Stack Options

<RenderDocs :options="data" :include="/nps\.stacks\.authelia\.(?!containers($|\.)).*/" />

## Container Extension

Authelia adds several container extension options to the existing `services.podman.containers.<name>` options.
These allow you to easily configure forward auth - for example for services that don't offer any built-in authentication.

Example:

```nix
{config, ...}: {
  nps.stacks.spliit.containers.spliit = {
    forwardAuth = {
      enable = true;
      rules = [
        {
          # For a full list of available rule options see <https://www.authelia.com/configuration/security/access-control/>
          policy = "two_factor";
        }
      ];
    };
  };
}
```

<RenderDocs :options="data" :include="/services\.podman\.containers\..+\.forwardAuth\..*/" />

## Container Aliases

<RenderDocs :options="data" :include="/nps\.stacks\.authelia.containers\..*/" />
