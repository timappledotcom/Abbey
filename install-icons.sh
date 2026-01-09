#!/bin/bash
# Install Abbey icons to the proper system locations for Linux desktops
# This script ensures the icon works on all Linux distros and desktop environments

set -e

# Determine install prefix
PREFIX="${PREFIX:-/usr/local}"
ICON_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor"
DESKTOP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"

# Use system directories if running as root
if [ "$(id -u)" = "0" ]; then
    ICON_DIR="$PREFIX/share/icons/hicolor"
    DESKTOP_DIR="$PREFIX/share/applications"
fi

echo "Installing Abbey icons to $ICON_DIR"
echo "Installing desktop file to $DESKTOP_DIR"

# Install icons at all sizes
for size in 16 24 32 48 64 128 256 512; do
    mkdir -p "$ICON_DIR/${size}x${size}/apps"
    install -Dm644 "assets/icons/hicolor/${size}x${size}/apps/app.abbey.Abbey.png" \
        "$ICON_DIR/${size}x${size}/apps/app.abbey.Abbey.png"
done

# Install scalable icon (high-res PNG fallback)
mkdir -p "$ICON_DIR/scalable/apps"
install -Dm644 "assets/icons/hicolor/scalable/apps/app.abbey.Abbey.png" \
    "$ICON_DIR/scalable/apps/app.abbey.Abbey.png"

# Install desktop file
mkdir -p "$DESKTOP_DIR"
install -Dm644 "data/app.abbey.Abbey.desktop" "$DESKTOP_DIR/app.abbey.Abbey.desktop"

# Update icon cache (required for some desktop environments)
if command -v gtk-update-icon-cache &> /dev/null; then
    echo "Updating icon cache..."
    gtk-update-icon-cache -f -t "$ICON_DIR" 2>/dev/null || true
fi

# Update desktop database (required for some desktop environments)
if command -v update-desktop-database &> /dev/null; then
    echo "Updating desktop database..."
    update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
fi

echo "Installation complete!"
echo "You may need to log out and log back in for changes to take effect."
