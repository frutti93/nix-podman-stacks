/*
In order to avoid secrets being visible in your Git repository, you can also pass widget values as paths.
This allows you to refer to sops secrets for example.

If a value is a passed as a 'path', it will be replaced by an placeholder and the necessary environment variable
will be automatically added to the homepage container.
*/
{config, ...}: {
  nps.stacks = {
    streaming.containers.sonarr.homepage.settings.widget = {
      enable = true;
      key = {path = config.sops.secrets."SONARR_API_KEY".path;};
    };
  };
}
