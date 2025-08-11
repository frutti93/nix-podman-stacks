/*
In order to avoid having a service show up in the homepage dashboard,
set the `enable` option to `false`.
*/
{
  nps.stacks = {
    streaming.containers.sonarr.homepage.enable = false;
  };
}
