#!/bin/bash
bash .oh-my-zsh/tools/install.sh

export DEBIAN_FRONTEND=noninteractive
SOURCE_DIR="plugins"
DEST_DIR="$HOME/.oh-my-zsh/custom/plugins"

echo "Copying plugins from $SOURCE_DIR to $DEST_DIR..."

mkdir -p "$DEST_DIR"

for dir in "$SOURCE_DIR"/*/; do
    [ -d "$dir" ] || continue  # Skip non-directories
    plugin_name=$(basename "$dir")
    echo "Copying $plugin_name..."
    cp -r "$dir" "$DEST_DIR/"
done

# Same for zsh config files
cp .zsh* $HOME
# autoswitch env might complain otherwise
if ! command -v python &> /dev/null && command -v python3 &> /dev/null; then
    echo "python not found, aliasing python3 to python"
    echo "alias python=python3" >> $HOME/.zshrc
fi

echo "Overwriting .gitconfig. You can find the original at $HOME/.gitconfig.old"
cp $HOME/.gitconfig $HOME/.gitconfig.old
cp .gitconfig $HOME/.gitconfig

echo "Overwriting ohmyzsh custom aliases."
cp aliases.zsh $HOME/.oh-my-zsh/custom/aliases.zsh

# Helper: detect base distro ID (e.g., ubuntu, debian, fedora)
detect_os_id() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo ""
    fi
}

# Helper: return 'ubuntu' or 'debian' when on a Debian-based system; empty otherwise
detect_debian_variant() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            ubuntu) echo "ubuntu"; return ;;
            debian) echo "debian"; return ;;
        esac
        case "$ID_LIKE" in
            *ubuntu*) echo "ubuntu"; return ;;
            *debian*) echo "debian"; return ;;
        esac
    fi
    echo ""
}

ensure_curl() {
    if command -v curl >/dev/null 2>&1; then
        return
    fi
    os_id="$(detect_os_id)"
    case "$os_id" in
        fedora)
            sudo dnf install -y curl
            ;;
        ubuntu|debian)
            sudo apt-get update -y
            sudo apt-get install -y curl
            ;;
    esac
}

echo "Installing GitHub CLI (gh)..."
if command -v gh >/dev/null 2>&1; then
    echo "gh is already installed."
else
    os_id="$(detect_os_id)"
    deb_variant="$(detect_debian_variant)"
    case "$os_id" in
        fedora)
            echo "Detected Fedora. Installing gh via dnf."
            sudo dnf install -y dnf-plugins-core
            sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
            sudo dnf install -y gh
            ;;
        *)
            if [ -n "$deb_variant" ]; then
                echo "Detected $deb_variant. Installing gh via apt."
                (type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
                    && sudo mkdir -p -m 755 /etc/apt/keyrings \
                    && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
                    && cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
                    && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
                    && sudo mkdir -p -m 755 /etc/apt/sources.list.d \
                    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
                    && sudo apt update \
                    && sudo apt install gh -y
            else
                echo "Unsupported or undetected distro. Please install GitHub CLI manually: https://cli.github.com/."
            fi
            ;;
    esac
fi

echo "Installing uv..."
if command -v uv >/dev/null 2>&1; then
    echo "uv is already installed."
else
    ensure_curl
    curl -LsSf https://astral.sh/uv/install.sh | sh
    if ! command -v uv >/dev/null 2>&1 && [ -x "$HOME/.local/bin/uv" ]; then
        if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.zshrc" 2>/dev/null; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
            echo "Added ~/.local/bin to PATH in .zshrc"
        fi
    fi
fi

