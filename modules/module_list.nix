let
  modules = {
    settings = ./settings.nix;
    adguard = ./adguard;
    aiostreams = ./aiostreams;
    audiobookshelf = ./audiobookshelf;
    beszel = ./beszel;
    blocky = ./blocky;
    calibre = ./calibre;
    changedetection = ./changedetection;
    crowdsec = ./crowdsec;
    dockdns = ./dockdns;
    dozzle = ./dozzle;
    filebrowser = ./filebrowser;
    forgejo = ./forgejo;
    freshrss = ./freshrss;
    healthchecks = ./healthchecks;
    homeassistant = ./homeassistant;
    homepage = ./homepage;
    immich = ./immich;
    ittools = ./it-tools;
    karakeep = ./karakeep;
    mealie = ./mealie;
    monitoring = ./monitoring;
    n8n = ./n8n;
    ntfy = ./ntfy;
    paperless = ./paperless;
    pocketid = ./pocket-id;
    stirling-pdf = ./stirling-pdf;
    streaming = ./streaming;
    traefik = ./traefik;
    uptime-kuma = ./uptime-kuma;
    vaultwarden = ./vaultwarden;
    wg-easy = ./wg-easy;
  };
in
  modules
  // {
    all = {imports = builtins.attrValues modules;};
  }
