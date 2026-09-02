#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"

echo "Building docs..."
nix build "$REPO_ROOT#book" -o result/docs/nix-podman-stacks/docs

echo "Serving at http://localhost:8081/nix-podman-stacks/docs/"
npx serve -l 8081 result/docs
