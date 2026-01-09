#!/bin/bash
# Uninstall Abbey icons from the system

set -e

PREFIX="${PREFIX:-/usr/local}"
ICON_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor"
DESKTOP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"

# Use system directories if running as root
if [ "$(id -u)" = "0" ]; then
    ICON_DIR="$PREFIX/share/icons/hicolor"
    DESKTOP_DIR="$PREFIX/share/applications"
fi

echo "Removing Abbey icons from $ICON_DIR"
echo "Removing desktop file from $DESKTOP_DIR"

# Remove icons at all sizes
for size in 16 24 32 48 64 128 256 512; do
    rm -f "$ICON_DIR/${size}x${size}/apps/app.abbey.Abbey.png"
done

# Remove scalable icon
rm -f "$ICON_DIR/scalable/apps/app.abbey.Abbey.png"

# Remove desktop file
rm -f "$DESKTOP_DIR/app.abbey.Abbey.desktop"

# Update icon cache
if command -v gtk-update-icon-cache &> /dev/null; then
    echo "Updating icon cache..."
    gtk-update-icon-cache -f -t "$ICON_DIR" 2>/dev/null || true
fi

# Update desktop database
if command -v update-desktop-database &> /dev/null; then
    echo "Updating desktop database..."
    update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
fi

echo "Uninstallation complete!"
