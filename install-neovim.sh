#!/usr/bin/env bash
set -euo pipefail

NVIM_VERSION="${NVIM_VERSION:-latest}"
NVIM_ROOT="${NVIM_ROOT:-$HOME/.local/opt/nvim}"
LOCAL_BIN="${LOCAL_BIN:-$HOME/.local/bin}"
CONFIG_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/nvim"
CONFIG_TARGET_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
export PATH="$LOCAL_BIN:$PATH"

detect_os_id() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "${ID:-}"
    else
        echo ""
    fi
}

detect_debian_variant() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "${ID:-}" in
            ubuntu|debian) echo "$ID"; return ;;
        esac
        case "${ID_LIKE:-}" in
            *ubuntu*) echo "ubuntu"; return ;;
            *debian*) echo "debian"; return ;;
        esac
    fi
    echo ""
}

install_system_deps() {
    local os_id deb_variant
    os_id="$(detect_os_id)"
    deb_variant="$(detect_debian_variant)"

    case "$os_id" in
        fedora)
            if command -v sudo >/dev/null 2>&1; then
                sudo dnf install -y curl git unzip tar gzip ripgrep fd-find gcc make
            else
                dnf install -y curl git unzip tar gzip ripgrep fd-find gcc make
            fi
            ;;
        *)
            if [ -n "$deb_variant" ]; then
                if command -v sudo >/dev/null 2>&1; then
                    sudo apt-get update -y
                    sudo apt-get install -y curl git unzip tar gzip ripgrep fd-find gcc make
                else
                    apt-get update -y
                    apt-get install -y curl git unzip tar gzip ripgrep fd-find gcc make
                fi
            else
                echo "Unsupported or undetected distro. Install curl, git, unzip, tar, gzip, ripgrep, fd, gcc, and make manually."
            fi
            ;;
    esac
}

neovim_asset_name() {
    local os arch
    os="$(uname -s)"
    arch="$(uname -m)"
    
    case "$os" in
        Darwin)
            case "$arch" in
                x86_64) echo "nvim-macos-x86_64.tar.gz" ;;
                arm64) echo "nvim-macos-arm64.tar.gz" ;;
                *) 
                    echo "Unsupported macOS CPU architecture: $arch" >&2
                    return 1
                    ;;
            esac
            ;;
        Linux)
            case "$arch" in
                x86_64|amd64) echo "nvim-linux-x86_64.tar.gz" ;;
                aarch64|arm64) echo "nvim-linux-arm64.tar.gz" ;;
                *) 
                    echo "Unsupported Linux CPU architecture: $arch" >&2
                    return 1
                    ;;
            esac
            ;;
        *)
            echo "Unsupported OS: $os" >&2
            return 1
            ;;
    esac
}

install_neovim() {
    local os arch asset url tmpdir extracted_dir
    os="$(uname -s)"
    arch="$(uname -m)"
    tmpdir=""
    
    case "$os" in
        Darwin)
            # Use Homebrew on macOS if available
            if command -v brew >/dev/null 2>&1; then
                echo "Installing Neovim via Homebrew"
                brew install --force neovim
                NVIM_ROOT="$(brew --prefix neovim)/lib/nvim"
                mkdir -p "$LOCAL_BIN"
                ln -sfn "$(brew --prefix neovim)/bin/nvim" "$LOCAL_BIN/nvim"
                echo "Installed Neovim via Homebrew to $NVIM_ROOT"
                return 0
            else
                # Fallback: download macOS binary directly
                echo "Homebrew not found. Downloading macOS Neovim binary directly."
                asset="$(neovim_asset_name)"
                
                if [ "$NVIM_VERSION" = "latest" ]; then
                    url="https://github.com/neovim/neovim/releases/latest/download/$asset"
                else
                    url="https://github.com/neovim/neovim/releases/download/$NVIM_VERSION/$asset"
                fi

                tmpdir="$(mktemp -d)"

                echo "Downloading Neovim from $url"
                curl -fL "$url" -o "$tmpdir/$asset"
                # On macOS, need to clear xattr to avoid "unknown developer" warning
                xattr -c "$tmpdir/$asset" 2>/dev/null || true
                tar -xzf "$tmpdir/$asset" -C "$tmpdir"
                extracted_dir="$tmpdir/${asset%.tar.gz}"

                rm -rf "$NVIM_ROOT"
                mkdir -p "$(dirname "$NVIM_ROOT")" "$LOCAL_BIN"
                mv "$extracted_dir" "$NVIM_ROOT"
                ln -sfn "$NVIM_ROOT/bin/nvim" "$LOCAL_BIN/nvim"

                rm -rf "$tmpdir"
                echo "Installed Neovim to $NVIM_ROOT"
            fi
            ;;
        Linux)
            asset="$(neovim_asset_name)"
            
            if [ "$NVIM_VERSION" = "latest" ]; then
                url="https://github.com/neovim/neovim/releases/latest/download/$asset"
            else
                url="https://github.com/neovim/neovim/releases/download/$NVIM_VERSION/$asset"
            fi

            tmpdir="$(mktemp -d)"

            echo "Downloading Neovim from $url"
            curl -fL "$url" -o "$tmpdir/$asset"
            tar -xzf "$tmpdir/$asset" -C "$tmpdir"
            extracted_dir="$tmpdir/${asset%.tar.gz}"

            rm -rf "$NVIM_ROOT"
            mkdir -p "$(dirname "$NVIM_ROOT")" "$LOCAL_BIN"
            mv "$extracted_dir" "$NVIM_ROOT"
            ln -sfn "$NVIM_ROOT/bin/nvim" "$LOCAL_BIN/nvim"

            rm -rf "$tmpdir"
            echo "Installed Neovim to $NVIM_ROOT"
            ;;
        *)
            echo "Unsupported OS for Neovim installation: $os" >&2
            return 1
            ;;
    esac
}

ensure_uv() {
    if command -v uv >/dev/null 2>&1 || [ -x "$HOME/.local/bin/uv" ]; then
        return
    fi

    echo "Installing uv for Python tooling..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
}

install_python_tools() {
    local uv_bin
    uv_bin="$(command -v uv || true)"
    if [ -z "$uv_bin" ] && [ -x "$HOME/.local/bin/uv" ]; then
        uv_bin="$HOME/.local/bin/uv"
    fi

    if [ -z "$uv_bin" ]; then
        echo "uv was not found after installation; skipping Python editor tools." >&2
        return 1
    fi

    "$uv_bin" tool install basedpyright --force
    "$uv_bin" tool install ruff --force
    "$uv_bin" tool install debugpy --force
}

install_config() {
    if [ ! -d "$CONFIG_SOURCE_DIR" ]; then
        echo "Neovim config source not found at $CONFIG_SOURCE_DIR" >&2
        return 1
    fi

    mkdir -p "$CONFIG_TARGET_DIR"
    cp -R "$CONFIG_SOURCE_DIR"/. "$CONFIG_TARGET_DIR"/
    echo "Installed Neovim config to $CONFIG_TARGET_DIR"
}

ensure_path_hint() {
    if ! grep -qF 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.zshrc" 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
        echo "Added ~/.local/bin to PATH in .zshrc"
    fi
}

main() {
    install_system_deps
    install_neovim
    ensure_uv
    install_python_tools
    install_config
    ensure_path_hint

    echo "Neovim Python setup complete. Start with: nvim"
}

main "$@"
