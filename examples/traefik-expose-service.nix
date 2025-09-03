/*
By default, Traefik is configured with two middlewares.
private: Only allows access to a service from private networks
public: Allows external access. Will setup ratelimits, geoblocking, security-headers and Crowdsec if enabled

The option `expose` controls which of these two middlewares is applied.
By default the `expose` option defaults to `false`, which results in the `private` middleware to be applied.

To expose a service, set the `expose` option to `true`, which results in the `public` middleware to be applied.

If you use the 'dockdns' stack, a DNS entry pointing to your public IP will be created automatically in Cloudflare.
When changing a service from public to private, the DNS entry can be automatically removed.
*/
{
  nps.stacks = {
    streaming.containers.jellyfin.expose = true;
  };
}
