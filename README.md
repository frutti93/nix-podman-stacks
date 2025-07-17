<p align="center">
   <img src="images/nix-podman-logo.png" alt="logo" width="130"/>
<p>
<p align="center">
   <a href="https://builtwithnix.org"><img src="https://img.shields.io/static/v1?logo=nixos&logoColor=white&label=&message=Built%20with%20Nix&color=41439a" alt="built with nix"></a>
   <img src="https://github.com/tarow/nix-podman-stacks/actions/workflows/ci.yaml/badge.svg" alt="Build">
   <a href="https://renovatebot.com">
   <img src="https://img.shields.io/badge/renovate-enabled-brightgreen.svg" alt="Renovate">
   </a>
</p>

# Nix Podman Stacks

<p align="center">
<img src="./images/homepage.png" alt="preview">
</p>

Collection of opinionated Podman stacks managed by [Home Manager](https://github.com/nix-community/home-manager).

The goal is to easily deploy various self-hosted projects, including a reverse proxy, dashboard and monitoring setup. Under the hood rootless Podman (Quadlets) will be used to run the containers. It works on most Linux distros including Ubuntu, Arch, Mint, Fedora & more and is not limited to NixOS.

The projects also contains integrations with Traefik, Homepage, Grafana and more. Some examples include:

- Enabling a stack will add the respective containers to Traefik and Homepage
- Enabling CrowdSec or PocketID will automatically configure necessary Traefik plugins and middlewares
- When stacks support exporting metrics, scrape configs for Prometheus can be automatically set up
- Similariy, Grafana dashboards for Traefik, Blocky & others can be automatically added
- and more ...

Disabling any of those options will of course also remove all associated configurations and containers.

While most stacks can be activated by setting a single flag, some stacks require setting mandatory values, especially for secrets.
For managing secrets, projects such as [sops-nix](https://github.com/Mic92/sops-nix) or [agenix](https://github.com/ryantm/agenix) can be used, which allow you to store your secrets along with the configuration inside a single Git repository.

## 📚 Option Documentation

Refer to the [documentation](https://tarow.github.io/nix-podman-stacks/) for a full list of available options.

Most stacks will rely or use a few centrally defined variables. These include:

| `tarow.podman` Option    | Description                                                                               |
| ------------------------ | ----------------------------------------------------------------------------------------- |
| `hostIP4Address`         | The IPv4 address of the host. Will be used for example in case of explicit port bindings. |
| `hostUid`                | The UID of the host user running the podman stacks.                                       |
| `storageBaseDir`         | Base storage location used for bind mounts. Used as a base location for bind mounts.      |
| `externalStorageBaseDir` | Base storage location used for media files, e.g. pictures used by Immich.                 |

## 📦 Available Stacks

- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/adguard-home.svg" style="width:1em;height:1em;" /> [Adguard](https://github.com/Tarow/nix-podman-stacks/tree/main//modules/adguard/default.nix)

- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/stremio.svg" style="width:1em;height:1em;" /> [AIOStreams](https://github.com/Tarow/nix-podman-stacks/tree/main//modules/aiostreams/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/audiobookshelf.svg" style="height:1em;" /> [Audiobookshelf](https://github.com/Tarow/nix-podman-stacks/tree/main//modules/audiobookshelf/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/beszel.svg" style="width:1em;height:1em;" /> [Beszel](https://github.com/Tarow/nix-podman-stacks/tree/main//modules/beszel/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/blocky.svg" style="width:1em;height:1em;" /> [Blocky](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/blocky/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/calibre-web.svg" style="width:1em;height:1em;" /> [Calibre-Web](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/calibre/default.nix)
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/calibre-web.svg" style="width:1em;height:1em;" /> Calibre-Web Automated
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/calibre-web-automated-book-downloader.png" style="width:1em;height:1em;" /> Calibre-Web Automated Book Downloader
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/changedetection.svg" style="width:1em;height:1em;" /> [Changedetection](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/changedetection/default.nix)
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/changedetection.svg" style="width:1em;height:1em;" /> Changedetection
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/chrome.svg" style="width:1em;height:1em;" /> Sock Puppet Browser
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/azure-dns.svg" style="width:1em;height:1em;" /> [DockDNS](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/dockdns/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/dozzle.svg" style="width:1em;height:1em;" /> [Dozzle](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/dozzle/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/filebrowser.svg" style="width:1em;height:1em;" /> [Filebrowser](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/filebrowser/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/forgejo.svg" style="width:1em;height:1em;" /> [Forgejo](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/forgejo/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/freshrss.svg" style="width:1em;height:1em;" /> [FreshRSS](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/freshrss/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/gatus.svg" style="width:1em;height:1em;" /> [Gatus](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/gatus/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/healthchecks.svg" style="width:1em;height:1em;" /> [Healthchecks](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/healchecks/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/home-assistant.svg" style="width:1em;height:1em;" /> [Home Assistant](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/homeassistant/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/homepage.png" style="width:1em;height:1em;" /> [Homepage](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/homepage/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/immich.svg" style="width:1em;height:1em;" /> [Immich](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/immich/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/it-tools.svg" style="width:1em;height:1em;" /> [IT-Tools](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/it-tools/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/karakeep.svg" style="width:1em;height:1em;" /> [Karakeep](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/karakeep/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/mealie.svg" style="width:1em;height:1em;" /> [Mealie](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/mealie/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/microbin.png" style="width:1em;height:1em;" /> [MicroBin](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/microbin/default.nix)
- 🔍 [Monitoring](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/monitoring/default.nix)
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/alloy.svg" style="width:1em;height:1em;" /> Alloy
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/grafana.svg" style="width:1em;height:1em;" /> Grafana
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/loki.svg" style="width:1em;height:1em;" /> Loki
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/prometheus.svg" style="width:1em;height:1em;" /> Prometheus
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/podman.svg" style="width:1em;height:1em;" /> Podman Metrics Exporter
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/n8n.svg" style="width:1em;height:1em;" /> [n8n](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/n8n/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/ntfy.svg" style="width:1em;height:1em;" /> [ntfy](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/ntfy/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/omni-tools.png" style="width:1em;" /> [OmniTools](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/omnitools/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/paperless.svg" style="width:1em;height:1em;" /> [Paperless-ngx](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/paperless/default.nix)
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/paperless.svg" style="width:1em;height:1em;" /> Paperless-ngx
  - 📂 FTP Server
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/pocket-id.svg" style="width:1em;height:1em;" /> [Pocket ID](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/pocket-id/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/stirling-pdf.svg" style="width:1em;height:1em;" /> [Stirling-PDF](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/stirling-pdf/default.nix)
- <span style="width:1em;height:1em;">📺</span> [Streaming](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/streaming/default.nix)
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/bazarr.svg" style="width:1em;height:1em;" /> Bazarr
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/flaresolverr.svg" style="width:1em;height:1em;" /> Flaresolverr
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/gluetun.svg" style="width:1em;height:1em;" /> Gluetun
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/jellyfin.svg" style="width:1em;height:1em;" /> Jellyfin
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/prowlarr.svg" style="width:1em;height:1em;" /> Prowlarr
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/qbittorrent.svg" style="width:1em;height:1em;" /> qBittorrent
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/radarr.svg" style="width:1em;height:1em;" /> Radarr
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/sonarr.svg" style="width:1em;height:1em;" /> Sonarr
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/traefik.svg" style="width:1em;height:1em;" /> [Traefik](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/traefik/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/uptime-kuma.svg" style="width:1em;height:1em;" /> [Uptime-Kuma](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/uptime-kuma/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/vaultwarden.svg" style="width:1em;height:1em;" /> [Vaultwarden](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/vaultwarden/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/wireguard.svg" style="width:1em;height:1em;" /> [wg-easy](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/wg-easy/default.nix)

## ⚙️ Prerequisites

- [Nix Installation](https://nixos.org/download/#nix-install-linux)
- `net.ipv4.ip_unprivileged_port_start=0` or any other way of allowing non-root processes to bind to ports below 1024

## 🚀 Setup

If you already have an existing flake setup, add this projects flake as an input and include the flake output `homeModules.all` in your Home Manager modules.

---

If you don't use Nix yet, you can use the projects template to get started:

1. `nix flake init --template github:Tarow/nix-podman-stacks`
2. Modify the `stacks.nix` file to enable, disable and modify settings according to your preferences
3. Generate your age key and create the `.sops.yaml` based on the `.sops.yaml.example`
4. Create the `secrets.yaml` file containing all secrets used in the stack configurations
5. Make sure to declare the used secrets in the `stacks.nix` file
6. Modify the `flake.nix` to reflect your system architecture, username and home directory
7. Apply your configuration: `nix run home-manager -- switch --experimental-features "nix-command flakes pipe-operators" -b bak --flake .#myhost`

This is just one example. Feel free to use a different tool for secret management or restructure files to your preference.

## 🔧 Customize Settings

The Podman stacks are mostly opinionated and configured to work out of the box.
Refer to [option documentation](https://tarow.github.io/nix-podman-stacks/) or the source code of each module to see which options are exposed on stack level and can be modified.
An example would be [Traefik](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/traefik/default.nix), which requires a domain to be set.
Also it ships with preconfigured static and dynamic configurations, but allows you to extend or customize those.

If the exposed options are not enough, you can always refer to the container definition directly by using the `tarow.podman.stacks.<stackname>.containers.<containername>` options.

Refer to the [examples](https://github.com/Tarow/nix-podman-stacks/tree/main/examples) to see different use cases of setting and overriding options.
