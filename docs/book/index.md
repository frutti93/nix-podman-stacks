---
layout: home
title: "Nix Podman Stacks - Declarative Self-Hosting with Nix & Podman"
description: "Deploy self-hosted services with Nix, Home Manager, and Podman Quadlets. Pre-configured integrations with Traefik, Homepage, Grafana, Authelia, and more - so everything works together out of the box."

hero:
  name: "Nix Podman Stacks"
  text: "Declarative Self-Hosting with Nix & Podman"
  tagline: "Deploy and manage self-hosted services using Home Manager, Podman Quadlets, and NixOS modules. Pre-configured integrations with Traefik, Homepage, Authelia, and dozens more."
  image:
    src: /images/nix-podman-logo.png
    alt: Nix Podman Stacks dashboard preview
  actions:
    - theme: brand
      text: Getting Started
      link: /getting-started
    - theme: brand
      text: Options
      link: /settings-options
    - theme: alt
      text: Examples
      link: /examples
    - theme: alt
      text: GitHub
      link: https://github.com/Tarow/nix-podman-stacks

features:
  - icon: ⚙️
    title: Simple Toggle
    details: Enable entire stacks with a single boolean flag. Sensible defaults work out of the box.
  - icon: 🔗
    title: Pre-configured Integrations
    details: Traefik, Homepage, Grafana, Authelia and more are wired together automatically.
  - icon: 🐧
    title: Works Everywhere
    details: Runs on Ubuntu, Arch, Fedora, Mint and more. Not limited to NixOS.
  - icon: 🔒
    title: Secret Management
    details: First-class support for sops-nix and agenix, with templating and file-based env injection.
  - icon: 📊
    title: Monitoring Built-in
    details: Prometheus metrics and Grafana dashboards for supported stacks, configured automatically.
  - icon: 🛡️
    title: Auth & Access Control
    details: Out of the box OIDC support for many applications and easy forward auth configuration options.
---

<!--@include: ./intro.md-->
