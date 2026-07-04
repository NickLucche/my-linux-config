# my-linux-config

Portable dev environment (zsh + oh-my-zsh + Neovim IDE + CLI tooling) managed with
[chezmoi](https://chezmoi.io). One command brings it to any Linux server or macOS box —
no sudo required for chezmoi itself.

## Install (single command)

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply NickLucche
```

This installs chezmoi to `~/.local/bin`, clones this repo into
`~/.local/share/chezmoi`, and applies everything: shell config, Neovim + config,
oh-my-zsh and plugins, and system/Python tooling.

Then start a new shell (`exec zsh`), or just log out and back in — interactive `bash`
auto-switches to `zsh`.

## What you get

- **zsh + oh-my-zsh** with `zsh-autosuggestions`, `zsh-fzf-history-search`,
  `autoswitch_virtualenv`, `alias-tips`. Custom aliases/functions live in
  `~/.config/omz-custom/` (set as `$ZSH_CUSTOM`).
- **Neovim** as a Python IDE: LSP (basedpyright, ruff), DAP debugging (debugpy),
  treesitter. Binary installed to `~/.local/opt/nvim`.
- **CLI tooling**: `uv`, `gh`, `ripgrep`, `fd`, `jq`, build tools.
- HPC/SLURM helpers: `node_attach`, `container_attach`, `remote_container_attach`.

## Secrets

All tokens live in a **single file**, `~/.config/dev-env/secrets.env`, which is
**not** in this repo. `~/.zshenv` sources it if it exists — `.zshenv` is read by
every zsh (interactive or not), so the exported vars are also inherited by child
processes and sbatch jobs. Create it per machine:

```sh
mkdir -p ~/.config/dev-env
# copy secrets.env.example (in this repo) and fill in real values, or scp your own
$EDITOR ~/.config/dev-env/secrets.env
```

Example contents:

```sh
export HF_TOKEN="..."
export WANDB_API_KEY="..."
export SBATCH_ACCOUNT="runtime"
```

## Day-to-day workflow

chezmoi keeps configs in two-way sync:

| Goal | Command |
|---|---|
| Pull repo updates onto this box | `chezmoi update` |
| Push a source edit to `$HOME` | `chezmoi apply` |
| Edit a config (edits the source) | `chezmoi edit ~/.zshrc` |
| Pull a live edit back into the repo | `chezmoi re-add` |
| See what would change | `chezmoi diff` / `chezmoi apply --dry-run -v` |
| Commit & push repo changes | `chezmoi cd` then normal git |

Externals (oh-my-zsh, plugins, Neovim) auto-refresh weekly on `apply`.

## Repo layout (chezmoi source)

```
dot_zshrc, dot_zshenv, dot_gitconfig         -> ~/.zshrc, ~/.zshenv, ~/.gitconfig
dot_config/nvim/init.lua                     -> ~/.config/nvim/init.lua
dot_config/omz-custom/{aliases,functions}.zsh-> ~/.config/omz-custom/  ($ZSH_CUSTOM)
.chezmoiexternal.toml.tmpl                   -> oh-my-zsh, zsh plugins, nvim binary
run_onchange_before_10-install-packages.sh.tmpl -> system + Python tooling
run_once_after_20-configure-bashrc.sh        -> bash->zsh auto-switch
secrets.env.example                          -> template for ~/.config/dev-env/secrets.env
```
