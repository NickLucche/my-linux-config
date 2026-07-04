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
# Only switch for interactive shells, and avoid recursion.
if [ -n "$PS1" ] && [ -z "$ZSH_VERSION" ] && command -v zsh >/dev/null 2>&1; then
    exec zsh
fi
EOF
echo "Added zsh auto-switch to $BASHRC"
