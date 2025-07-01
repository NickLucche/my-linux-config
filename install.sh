#!/bin/bash
bash .oh-my-zsh/tools/install.sh

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

echo "Overwriting .gitconfig"
cp .gitconfig $HOME/

echo "Copying aliases"
cp aliases.zsh $HOME/.oh-my-zsh/custom/aliases.zsh
