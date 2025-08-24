/*
By default, Traefik is configured with two middlewares.
private: Only allows access to a service from private networks
public: Allows external access. Will setup ratelimits, geoblocking, security-headers and Crowdsec if enabled

By default all services are configured with the private middleware.
To expose a service, we can set the public middleware using a containers `traefik.middleware` attribute set

If you use the 'dockdns' stack, a DNS entry pointing to your public IP will be created automatically in Cloudflare.
When changing a service from public to private, the DNS entry can be automatically removed.
*/
{
  nps.stacks = {
    streaming.containers.jellyfin.traefik.middleware.public.enable = true;
  };
}
