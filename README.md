# Nix Podman Stacks

Collection of opinionated Podman stacks managed by [Home Manager](https://github.com/nix-community/home-manager).

[![built with nix](https://img.shields.io/static/v1?logo=nixos&logoColor=white&label=&message=Built%20with%20Nix&color=41439a)](https://builtwithnix.org)
![Build](https://github.com/tarow/nix-podman-stacks/actions/workflows/ci.yaml/badge.svg)
[![Renovate](https://img.shields.io/badge/renovate-enabled-brightgreen.svg)](https://renovatebot.com)

![preview](./screenshots/homepage.png)

The goal is to easily deploy various self-hosted projects, including a reverse proxy, dashboard and monitoring setup.
The projects also contains integrations with Traefik, Homepage, Grafana and more. Some examples include:

- Enabling a stack will add the respective containers to Traefik and Homepage
- Enabling CrowdSec or PocketID will automatically configure necessary Traefik plugins and middlewares
- When stacks support exporting metrics, scrape configs for Prometheus can be automatically set up
- Similariy, Grafana dashboards for Traefik, Blocky & others can be automatically added
- and more ...

Disabling any of those options will of course also remove all associated configurations and containers.

While most stacks can be activated by setting a single flag, some stacks require setting mandatory values, especially for secrets.
For managing secrets, projects such as [sops-nix](https://github.com/Mic92/sops-nix) or [agenix](https://github.com/ryantm/agenix) can be used, which allow you to store your secrets along with the configuration inside a single Git repository.

## Option Documentation

Refer to the [documentation](https://tarow.github.io/nix-podman-stacks/) for a full list of available options.

Most stacks will rely or use a few centrally defined variables. These include:

| `tarow.podman` Option    | Description                                                                               |
| ------------------------ | ----------------------------------------------------------------------------------------- |
| `hostIP4Address`         | The IPv4 address of the host. Will be used for example in case of explicit port bindings. |
| `hostUid`                | The UID of the host user running the podman stacks.                                       |
| `storageBaseDir`         | Base storage location used for bind mounts. Used as a base location for bind mounts.      |
| `externalStorageBaseDir` | Base storage location used for media files, e.g. pictures used by Immich.                 |

## Available Stacks

- [Adguard](https://github.com/Tarow/nix-podman-stacks/tree/main//modules/adguard/default.nix)
- [AIOStreams](https://github.com/Tarow/nix-podman-stacks/tree/main//modules/aiostreams/default.nix)
- [Audiobookshelf](https://github.com/Tarow/nix-podman-stacks/tree/main//modules/audiobookshelf/default.nix)
- [Beszel](https://github.com/Tarow/nix-podman-stacks/tree/main//modules/beszel/default.nix)
- [Blocky](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/blocky/default.nix)
- [Calibre-Web](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/calibre/default.nix)
  - Calibre-Web Automated
  - Calibre-Web Automated Book Downloader
- [Changedetection](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/changedetection/default.nix)
  - Changedetection
  - Sock Puppet Browser
- [DockDNS](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/dockdns/default.nix)
- [Dozzle](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/dozzle/default.nix)
- [Filebrowser](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/filebrowser/default.nix)
- [Forgejo](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/forgejo/default.nix)
- [FreshRSS](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/freshrss/default.nix)
- [Gatus](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/gatus/default.nix)
- [Healthchecks](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/healchecks/default.nix)
- [Home Assistant](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/homeassistant/default.nix)
- [Homepage](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/homepage/default.nix)
- [Immich](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/immich/default.nix)
- [IT-Tools](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/it-tools/default.nix)
- [Karakeep](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/karakeep/default.nix)
- [Mealie](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/mealie/default.nix)
- [MicroBin](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/microbin/default.nix)
- [Monitoring](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/monitoring/default.nix)
  - Alloy
  - Grafana
  - Loki
  - Prometheus
  - Podman Metrics Exporter
- [n8n](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/n8n/default.nix)
- [ntfy](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/ntfy/default.nix)
- [OmniTools](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/omnitools/default.nix)
- [Paperless-ngx](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/paperless/default.nix)
  - Paperless-ngx
  - FTP Server
- [Pocket ID](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/pocket-id/default.nix)
- [Stirling-PDF](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/stirling-pdf/default.nix)
- [Streaming](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/streaming/default.nix)
  - Bazarr
  - Flaresolverr
  - Gluetun
  - Jellyfin
  - Prowlarr
  - qBittorrent
  - Radarr
  - Sonarr
- [Traefik](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/traefik/default.nix)
- [Uptime-Kuma](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/uptime-kuma/default.nix)
- [Vaultwarden](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/vaultwarden/default.nix)
- [wg-easy](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/wg-easy/default.nix)

## Prerequisites

- [Nix Installation](https://nixos.org/download/#nix-install-linux)
- `net.ipv4.ip_unprivileged_port_start=0` or any other way of allowing non-root processes to bind to ports below 1024

## Setup

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

## Customize Settings

The Podman stacks are mostly opinionated and configured to work out of the box.
Refer to [option documentation](https://tarow.github.io/nix-podman-stacks/) or the source code of each module to see which options are exposed on stack level and can be modified.
An example would be [Traefik](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/traefik/default.nix), which requires a domain to be set.
Also it ships with preconfigured static and dynamic configurations, but allows you to extend or customize those.

If the exposed options are not enough, you can always refer to the container definition directly by using the `tarow.podman.stacks.<stackname>.containers.<containername>` options.

Refer to the [examples](https://github.com/Tarow/nix-podman-stacks/tree/main/examples) to see different use cases of setting and overriding options.
