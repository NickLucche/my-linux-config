#!/usr/bin/env bash
# Managed by chezmoi. Runs once per machine.
# On boxes where you can't `chsh` to zsh, make interactive bash exec zsh.
set -euo pipefail

BASHRC="$HOME/.bashrc"
MARKER="# Auto-switch to zsh (added by chezmoi)"

[ -f "$BASHRC" ] || touch "$BASHRC"

if grep -qF "$MARKER" "$BASHRC"; then
    echo "zsh auto-switch already present in $BASHRC"
    exit 0
fi

if ! command -v zsh >/dev/null 2>&1; then
    echo "zsh not found; skipping bash->zsh auto-switch (install zsh, then re-run 'chezmoi apply')." >&2
    exit 0
fi

cat >> "$BASHRC" <<'EOF'

# Auto-switch to zsh (added by chezmoi)
# `case $- in *i*)` matches INTERACTIVE shells only. This is what keeps it safe:
# non-interactive contexts that still source ~/.bashrc — `ssh host cmd`, srun/
# sbatch job steps, scp, rsync — have no 'i' in $-, so they never exec zsh.
# (Using $PS1 here instead is a known footgun that breaks srun.)
case $- in
  *i*)
    if [ -z "$ZSH_VERSION" ] && command -v zsh >/dev/null 2>&1; then
      export SHELL="$(command -v zsh)"
      exec zsh
    fi
    ;;
esac
EOF
echo "Added zsh auto-switch to $BASHRC"
