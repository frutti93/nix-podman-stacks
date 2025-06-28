/*
Most containers come with preconfigured homepage coniguration.
They will set category, name and description.
You can override these values if desired.

The options are not available on stack level, so we can refer to the container options
*/
{lib, ...}: {
  tarow.stacks = {
    # ...
    adguard.containers.adguard.homepage = {
      name = lib.mkForce "New Name";
      category = lib.mkForce "New Category";
      settings = {
        description = lib.mkForce "New Description";
        icon = lib.mkForce "si-adblock";
      };
    };
    # ...
  };
}
