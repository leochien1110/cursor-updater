#!/bin/bash

# Cursor IDE Update Script
# This script checks for the latest version of Cursor IDE and updates it if necessary

set -euo pipefail

# Configuration
OPT_DIR="/opt"
CURSOR_SYMLINK="$OPT_DIR/cursor.appimage"
TEMP_DIR="/tmp/cursor-update"
LOG_PREFIX="[Cursor Updater]"

# Logging function
log() {
    echo "$LOG_PREFIX $1" >&2
}

# Check system architecture and set download URL
get_download_url() {
    local arch=$(uname -m)
    case $arch in
        x86_64)
            echo "https://www.cursor.com/download/stable/linux-x64"
            ;;
        aarch64|arm64)
            echo "https://www.cursor.com/download/stable/linux-arm64"
            ;;
        *)
            log "Error: Unsupported architecture: $arch"
            exit 1
            ;;
    esac
}

# Get the version from an AppImage file
get_appimage_version() {
    local appimage_path="$1"
    if [[ ! -f "$appimage_path" ]]; then
        echo ""
        return
    fi
    
    # Extract version from filename or try to get it from the AppImage
    local filename=$(basename "$appimage_path")
    if [[ $filename =~ cursor-([0-9]+\.[0-9]+\.[0-9]+.*)-linux ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo ""
    fi
}

# Get current installed version
get_current_version() {
    local cursor_files=($(find "$OPT_DIR" -name "cursor-*" -type f 2>/dev/null || true))
    if [[ ${#cursor_files[@]} -eq 0 ]]; then
        echo ""
        return
    fi
    
    # Get the version from the most recent cursor file
    local latest_file=""
    local latest_time=0
    for file in "${cursor_files[@]}"; do
        local file_time=$(stat -c %Y "$file" 2>/dev/null || echo 0)
        if [[ $file_time -gt $latest_time ]]; then
            latest_time=$file_time
            latest_file="$file"
        fi
    done
    
    get_appimage_version "$latest_file"
}

# Download the latest version and get its filename
download_latest() {
    local download_url="$1"
    
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    log "Downloading latest Cursor IDE from $download_url"
    
    # Clean up any previous downloads
    rm -f "$TEMP_DIR"/*cursor*.AppImage* 2>/dev/null || true
    
    # Download with content disposition to get the proper filename
    if ! wget --content-disposition "$download_url"; then
        log "Error: Failed to download Cursor IDE"
        exit 1
    fi
    
    # Find the downloaded file (case insensitive, handle various extensions)
    local downloaded_file=$(find "$TEMP_DIR" -iname "*cursor*.AppImage*" -type f | head -n1)
    if [[ -z "$downloaded_file" ]]; then
        log "Error: Downloaded file not found"
        log "Available files in temp directory:"
        ls -la "$TEMP_DIR" >&2
        exit 1
    fi
    
    echo "$downloaded_file"
}



# Install the new version
install_cursor() {
    local downloaded_file="$1"
    local filename=$(basename "$downloaded_file")
    
    # Clean filename - remove any trailing numbers that wget might add
    local clean_filename=$(echo "$filename" | sed 's/\.[0-9]*$//')
    # Ensure it has .AppImage extension
    if [[ ! "$clean_filename" =~ \.AppImage$ ]]; then
        clean_filename="${clean_filename}.AppImage"
    fi
    
    local target_path="$OPT_DIR/$clean_filename"
    
    log "Installing $filename to $target_path"
    
    # Make executable
    chmod +x "$downloaded_file"
    
    # Move to /opt with clean name
    sudo mv "$downloaded_file" "$target_path"
    
    # Update symlink
    sudo rm -f "$CURSOR_SYMLINK"
    sudo ln -sf "$target_path" "$CURSOR_SYMLINK"
    
    log "Successfully installed Cursor IDE: $clean_filename"
}

# Clean up old versions (keep only the latest)
cleanup_old_versions() {
    log "Cleaning up old Cursor versions..."
    
    local cursor_files=($(find "$OPT_DIR" -name "cursor-*" -type f 2>/dev/null || true))
    local symlink_target=""
    
    if [[ -L "$CURSOR_SYMLINK" ]]; then
        symlink_target=$(readlink "$CURSOR_SYMLINK")
    fi
    
    for file in "${cursor_files[@]}"; do
        if [[ "$file" != "$symlink_target" ]]; then
            log "Removing old version: $(basename "$file")"
            sudo rm -f "$file"
        fi
    done
}

# Main execution
main() {
    log "Starting Cursor IDE update check..."
    
    # Get download URL based on architecture
    local download_url=$(get_download_url)
    log "Architecture: $(uname -m), Download URL: $download_url"
    
    # Get current version
    local current_version=$(get_current_version)
    if [[ -n "$current_version" ]]; then
        log "Current version: $current_version"
    else
        log "No current installation found"
    fi
    
    # Download latest version
    local downloaded_file=$(download_latest "$download_url")
    local new_version=$(get_appimage_version "$downloaded_file")
    
    if [[ -n "$new_version" ]]; then
        log "Downloaded version: $new_version"
    else
        log "Warning: Could not determine version of downloaded file"
    fi
    
    # Compare versions
    if [[ -n "$current_version" && "$current_version" == "$new_version" ]]; then
        log "Already running the latest version ($current_version). No update needed."
        rm -rf "$TEMP_DIR"
        exit 0
    fi
    
    # Install new version
    install_cursor "$downloaded_file"
    
    # Clean up old versions
    cleanup_old_versions
    
    # Clean up temp directory
    rm -rf "$TEMP_DIR"
    
    log "Update completed successfully!"
}

# Run main function
main "$@" 