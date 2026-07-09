#!/usr/bin/env bash
# Managed by chezmoi. Runs once per machine. Configures ~/.bashrc for boxes
# where bash is the entry shell:
#   1. source the local dev-env secrets file, so bash sessions (and srun/ssh
#      command steps that read ~/.bashrc) get tokens even without switching to zsh
#   2. auto-switch interactive bash to zsh when possible
# Both blocks are marker-guarded so re-runs never duplicate them.
set -euo pipefail

BASHRC="$HOME/.bashrc"
[ -f "$BASHRC" ] || touch "$BASHRC"

# --- 1. secrets sourcing ----------------------------------------------------
SECRETS_MARKER="# Load dev-env secrets (added by chezmoi)"
if grep -qF "$SECRETS_MARKER" "$BASHRC"; then
    echo "secrets sourcing already present in $BASHRC"
else
    cat >> "$BASHRC" <<'EOF'

# Load dev-env secrets (added by chezmoi)
# Single file of tokens (HF_TOKEN, API keys, SLURM account vars, ...), carried
# out-of-band and NOT tracked by git. Mirrors what ~/.zshenv does for zsh.
[ -f "$HOME/.config/dev-env/secrets.env" ] && . "$HOME/.config/dev-env/secrets.env"
EOF
    echo "Added secrets sourcing to $BASHRC"
fi

# --- 2. bash -> zsh auto-switch ---------------------------------------------
SWITCH_MARKER="# Auto-switch to zsh (added by chezmoi)"
if grep -qF "$SWITCH_MARKER" "$BASHRC"; then
    echo "zsh auto-switch already present in $BASHRC"
elif ! command -v zsh >/dev/null 2>&1; then
    echo "zsh not found; skipping bash->zsh auto-switch (install zsh, then re-run 'chezmoi apply')." >&2
else
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
fi
