#!/bin/bash

# Install the fan control tray icons into the user's icon theme.
# Source of truth for the icons is assets/icons/*.svg

set -e

SRC_DIR="$(dirname "$(readlink -f "$0")")/assets/icons"
ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"

if [ ! -d "$SRC_DIR" ]; then
    echo "❌ Icon source directory not found: $SRC_DIR"
    exit 1
fi

mkdir -p "$ICON_DIR"
install -m 644 "$SRC_DIR"/fan-*.svg "$ICON_DIR/"

echo "Icons installed in $ICON_DIR"
echo "Updating icon cache..."
gtk-update-icon-cache -f "$HOME/.local/share/icons/hicolor" 2>/dev/null || true

echo "✓ Icons installed successfully!"
echo ""
echo "Icon mapping:"
echo "  • fan-quiet: Blue (Quiet mode)"
echo "  • fan-balanced: Green (Balanced mode)"
echo "  • fan-performance: Orange (Performance mode)"
echo "  • fan-gmode: Red with 'G' (G-Mode)"
