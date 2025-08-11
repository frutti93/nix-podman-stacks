/*
By default services in a category are sorted alphabetically.
You can set the `rank` attribute to influence the order of services.
For example, to move the `traefik` and `wg-easy` services to the top:
*/
{
  nps.stacks = {
    traefik.containers.traefik.homepage.settings.rank = 10;
    wg-easy.containers.wg-easy.homepage.settings.rank = 20;
  };
}
