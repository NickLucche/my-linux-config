#!/usr/bin/env bash
# Managed by chezmoi. Create local, non-managed directories so files can be
# dropped in without mkdir'ing first. In particular the secrets file lives at
# ~/.config/dev-env/secrets.env, which chezmoi intentionally does NOT track
# (carried out-of-band); this just makes the target directory exist.
set -euo pipefail

mkdir -p "$HOME/.config/dev-env"
