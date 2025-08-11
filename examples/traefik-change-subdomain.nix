/*
The subdomain which a service is reachable at is controlled by the containers `traefik.name` attribute.
Is it preconfigured for every container.
You can override the subdomain, e.g. make sonarr available at
'series.mydomain.com' instead of 'sonarr.mydomain.com'.

Changes to the traefik subdomain will automatically be reflected on the Homepage dashboard too,
so the href will update automatically.
*/
{lib, ...}: {
  nps.stacks = {
    streaming.containers.sonarr.traefik.name = lib.mkForce "series";
  };
}
