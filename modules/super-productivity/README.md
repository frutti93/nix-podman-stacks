Todo list and time tracking with self-hosted SuperSync

- [Github](https://github.com/super-productivity/super-productivity)
- [Website](https://super-productivity.com/)

## Example

Web app only (no sync):

```nix
{
  nps.stacks.super-productivity = {
    enable = true;
  };
}
```

With SuperSync:

```nix
{config, ...}: {
  nps.stacks.super-productivity = {
    enable = true;
    enableSync = true;
    jwtSecretFile = config.sops.secrets."super-productivity/jwt_secret".path;
    db.passwordFile = config.sops.secrets."super-productivity/db_password".path;
    smtp = {
      host = "mail.example.com";
      user = "user";
      passwordFile = config.sops.secrets."super-productivity/smtp_password".path;
      from = "SuperSync <noreply@example.com>";
    };
  };
}
```
