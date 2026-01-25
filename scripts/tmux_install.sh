#!/usr/bin/env bash

SHELL_RC=""
SHELL_NAME="$(basename "$SHELL")"

case "$SHELL_NAME" in
    bash)
        SHELL_RC="$HOME/.bashrc"
        ;;
    zsh)
        SHELL_RC="$HOME/.zshrc"
        ;;
    *)
        echo "Error: Unsupported login shell '$SHELL'. Only bash and zsh are supported."
        exit 1
        ;;
esac

echo "📦 Tmux Config Installer"
echo ""

ALIAS_LINE='[ ! -f ~/.config/tmux/scripts/tmux_aliases.sh ] || source ~/.config/tmux/scripts/tmux_aliases.sh'
if ! grep -qF "$ALIAS_LINE" "$SHELL_RC" 2>/dev/null; then
    echo "" >> "$SHELL_RC"
    echo "# Tmux aliases" >> "$SHELL_RC"
    echo "$ALIAS_LINE" >> "$SHELL_RC"
    echo "✓ Added aliases to $SHELL_RC"
else
    echo "✓ Aliases already present in $SHELL_RC"
fi

if [ -L "$HOME/.tmux.conf" ]; then
    echo "✓ Symlink already exists: ~/.tmux.conf -> ~/.config/tmux/tmux.conf"
elif [ -e "$HOME/.tmux.conf" ]; then
    echo "Warning: ~/.tmux.conf already exists (not a symlink). Backup created."
    backup_path="$HOME/.tmux.conf.bak.$(date +%Y%m%d_%H%M%S)"
    mv "$HOME/.tmux.conf" "$backup_path"
    ln -s "$HOME/.config/tmux/tmux.conf" "$HOME/.tmux.conf"
    echo "✓ Created symlink (original backed up to $backup_path)"
else
    ln -s "$HOME/.config/tmux/tmux.conf" "$HOME/.tmux.conf"
    echo "✓ Created symlink: ~/.tmux.conf -> ~/.config/tmux/tmux.conf"
fi

echo ""

TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
    echo "📥 Installing TPM (Tmux Plugin Manager)..."
    mkdir -p "$HOME/.tmux/plugins"
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    echo "✓ TPM installed to $TPM_DIR"
    tmux kill-server
    tmux start-server
    tmux kill-server
    echo "✓ Tmux server restarted."
else
    echo "✓ TPM already installed at $TPM_DIR"
fi

echo ""
echo "🔌 Installing tmux plugins..."
if [ -x "$TPM_DIR/bin/install_plugins" ]; then
    "$TPM_DIR/bin/install_plugins"
    echo "✓ Plugins installed"
else
    echo "Warning: TPM install script not found. Plugins not installed."
    echo "Run manually inside tmux: press prefix + I or run: $TPM_DIR/bin/install_plugins"
fi

echo "🔄 Reloading Tmux Configuration..."
tmux kill-server
tmux start-server
tmux source-file ~/.tmux.conf
sleep 1
tmux kill-server

echo ""
echo "✅ Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Restart your shell or run: source $SHELL_RC"
echo "  2. Start tmux: tmux start-server"
echo "  3. (Optional) Reload config inside tmux: tmux source-file ~/.tmux.conf"
