#!/bin/bash

# Cursor IDE Updater Service Setup Script
# This script sets up the systemd service and timer for daily automatic updates

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_NAME="cursor-update"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
TIMER_FILE="/etc/systemd/system/${SERVICE_NAME}.timer"

log() {
    echo "[Cursor Updater Setup] $1" >&2
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    log "Error: This script should not be run as root. It will use sudo when needed."
    exit 1
fi

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    for cmd in sudo systemctl; do
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

# Create systemd service file
create_service() {
    log "Creating systemd service file..."
    
    sudo tee "$SERVICE_FILE" > /dev/null << EOF
[Unit]
Description=Cursor IDE Updater
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=root
ExecStart=$SCRIPT_DIR/update-cursor.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    log "Service file created at $SERVICE_FILE"
}

# Create systemd timer file
create_timer() {
    log "Creating systemd timer file..."
    
    sudo tee "$TIMER_FILE" > /dev/null << EOF
[Unit]
Description=Run Cursor IDE Updater daily
Requires=${SERVICE_NAME}.service

[Timer]
OnCalendar=daily
RandomizedDelaySec=3600
Persistent=true

[Install]
WantedBy=timers.target
EOF
    
    log "Timer file created at $TIMER_FILE"
}

# Enable and start the timer
enable_timer() {
    log "Enabling and starting the timer..."
    
    # Reload systemd daemon
    sudo systemctl daemon-reload
    
    # Enable the timer
    sudo systemctl enable "$SERVICE_NAME.timer"
    
    # Start the timer
    sudo systemctl start "$SERVICE_NAME.timer"
    
    log "Timer enabled and started successfully"
}

# Show status
show_status() {
    log "Timer status:"
    systemctl status "$SERVICE_NAME.timer" --no-pager || true
    
    echo
    log "Next scheduled run:"
    systemctl list-timers "$SERVICE_NAME.timer" --no-pager || true
}

main() {
    log "Setting up Cursor IDE daily updater service..."
    
    # Check dependencies
    check_dependencies
    
    # Ensure update script exists and is executable
    if [[ ! -f "$SCRIPT_DIR/update-cursor.sh" ]]; then
        log "Error: update-cursor.sh not found in $SCRIPT_DIR"
        exit 1
    fi
    
    chmod +x "$SCRIPT_DIR/update-cursor.sh"
    
    # Create service and timer files
    create_service
    create_timer
    
    # Enable and start timer
    enable_timer
    
    # Show status
    show_status
    
    log "Daily updater service setup completed successfully!"
    log ""
    log "The updater will now run daily at a random time (with up to 1 hour delay)."
    log ""
    log "Manual operations:"
    log "  - Test the updater: sudo systemctl start $SERVICE_NAME.service"
    log "  - Check update logs: journalctl -u $SERVICE_NAME.service -f"
    log "  - Check timer status: systemctl status $SERVICE_NAME.timer"
    log "  - Stop daily updates: sudo systemctl stop $SERVICE_NAME.timer"
    log "  - Disable daily updates: sudo systemctl disable $SERVICE_NAME.timer"
}

main "$@" 