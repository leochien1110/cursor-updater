#!/bin/bash

# Cursor IDE Initial Setup Script
# This script installs the latest version of Cursor IDE and sets it up in the Application drawer

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DESKTOP_FILE="$HOME/.local/share/applications/cursor.desktop"
ICON_FILE="$HOME/.local/share/icons/cursor-icon.png"

log() {
    echo "[Cursor Init] $1" >&2
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    log "Error: This script should not be run as root. Please run as a regular user."
    exit 1
fi

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    for cmd in wget sudo; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log "Error: Missing required dependencies: ${missing_deps[*]}"
        log "Please install them and try again."
        exit 1
    fi
}

# Create desktop entry
create_desktop_entry() {
    log "Creating desktop entry..."
    
    # Create directories if they don't exist
    mkdir -p "$(dirname "$DESKTOP_FILE")"
    mkdir -p "$(dirname "$ICON_FILE")"
    
    # Copy icon if it exists
    if [[ -f "$SCRIPT_DIR/res/cursor-icon.png" ]]; then
        cp "$SCRIPT_DIR/res/cursor-icon.png" "$ICON_FILE"
        log "Copied cursor icon to $ICON_FILE"
    else
        log "Warning: Icon file not found at $SCRIPT_DIR/res/cursor-icon.png"
        # Use a fallback icon
        ICON_FILE="cursor"
    fi
    
    # Create desktop entry
    cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=Cursor
Comment=AI-powered code editor
GenericName=Text Editor
Exec=/opt/cursor.appimage
Icon=$ICON_FILE
Type=Application
StartupNotify=true
Categories=Development;TextEditor;
MimeType=text/plain;
StartupWMClass=Cursor
EOF
    
    # Make desktop file executable
    chmod +x "$DESKTOP_FILE"
    
    log "Desktop entry created at $DESKTOP_FILE"
}

# Update desktop database
update_desktop_database() {
    if command -v update-desktop-database &> /dev/null; then
        log "Updating desktop database..."
        update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    fi
}

main() {
    log "Starting Cursor IDE initial setup..."
    
    # Check dependencies
    check_dependencies
    
    # Run the update script to install the latest version
    log "Installing latest Cursor IDE..."
    if [[ -f "$SCRIPT_DIR/update-cursor.sh" ]]; then
        chmod +x "$SCRIPT_DIR/update-cursor.sh"
        sudo "$SCRIPT_DIR/update-cursor.sh"
    else
        log "Error: update-cursor.sh not found in $SCRIPT_DIR"
        exit 1
    fi
    
    # Create desktop entry
    create_desktop_entry
    
    # Update desktop database
    update_desktop_database
    
    log "Initial setup completed successfully!"
    log "You should now be able to find Cursor in your Application drawer."
    log "You can also run it directly with: /opt/cursor.appimage"
}

main "$@" 