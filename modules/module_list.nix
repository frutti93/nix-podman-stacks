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
    docker-socket-proxy = ./docker-socket-proxy;
    filebrowser = ./filebrowser;
    forgejo = ./forgejo;
    freshrss = ./freshrss;
    gatus = ./gatus;
    healthchecks = ./healthchecks;
    homeassistant = ./homeassistant;
    homepage = ./homepage;
    immich = ./immich;
    ittools = ./it-tools;
    karakeep = ./karakeep;
    mealie = ./mealie;
    microbin = ./microbin;
    monitoring = ./monitoring;
    n8n = ./n8n;
    ntfy = ./ntfy;
    omnitools = ./omnitools;
    paperless = ./paperless;
    pocketid = ./pocket-id;
    romm = ./romm;
    stirling-pdf = ./stirling-pdf;
    streaming = ./streaming;
    traefik = ./traefik;
    uptime-kuma = ./uptime-kuma;
    vaultwarden = ./vaultwarden;
    wg-easy = ./wg-easy;
    wg-portal = ./wg-portal;
  };
in
  modules
  // {
    all = {imports = builtins.attrValues modules;};
  }
