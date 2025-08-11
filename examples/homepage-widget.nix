/*
You can also enable homepage widgets.
For the necessary values, refer to the widget documentation of the hompage project: https://gethomepage.dev/widgets/

The 'url' and 'type' attributes are already preconfigured for every widget.
To enable a widget, we need to set the enable flag and add missing information
*/
{
  nps.stacks = {
    streaming.containers.sonarr.homepage.settings.widget = {
      enable = true;

      # In order to avoid having secrets visible in your config refer to the `homepage-widget-secret` example
      key = "secret";
    };
  };
}
