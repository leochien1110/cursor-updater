#!/bin/bash

# Cursor IDE Update Script
# Checks for the latest version of Cursor IDE and updates it if necessary

set -euo pipefail

# Configuration
INSTALL_PATH="/opt/cursor.appimage"
LOG_PREFIX="[Cursor Updater]"

# Logging function
log() {
    echo "$LOG_PREFIX $1" >&2
}

# Get platform string based on system architecture
get_platform() {
    local arch=$(uname -m)
    case $arch in
        x86_64)
            echo "linux-x64"
            ;;
        aarch64|arm64)
            echo "linux-arm64"
            ;;
        *)
            log "Error: Unsupported architecture: $arch"
            exit 1
            ;;
    esac
}

# Get latest version and download URL from Cursor API
get_latest_cursor_info() {
    local platform="$1"
    local api_url="https://www.cursor.com/api/download?platform=${platform}&releaseTrack=latest"
    
    log "Fetching latest version info from API..."
    
    local response=$(curl -s -H "User-Agent: Cursor-Version-Checker" -H "Cache-Control: no-cache" "$api_url")
    if [[ $? -ne 0 ]] || [[ -z "$response" ]]; then
        log "Error: Failed to fetch version info from API"
        return 1
    fi
    
    # Extract version and download URL from JSON response
    local version=$(echo "$response" | grep -o '"version":"[^"]*"' | cut -d'"' -f4 2>/dev/null)
    local download_url=$(echo "$response" | grep -o '"downloadUrl":"[^"]*"' | cut -d'"' -f4 2>/dev/null)
    
    if [[ -z "$version" ]] || [[ -z "$download_url" ]]; then
        log "Error: Could not parse version or download URL from API response"
        return 1
    fi
    
    echo "$version|$download_url"
    return 0
}

# Compare version strings using semantic versioning
version_greater_than() {
    local version1="$1"
    local version2="$2"
    
    [[ -z "$version2" ]] && return 0
    [[ -z "$version1" ]] && return 1
    
    # Convert to comparable format and use sort -V
    local v1=$(echo "$version1" | sed 's/[^0-9.]//g')
    local v2=$(echo "$version2" | sed 's/[^0-9.]//g')
    
    local higher=$(printf '%s\n%s\n' "$v1" "$v2" | sort -V | tail -n1)
    [[ "$v1" == "$higher" ]] && [[ "$v1" != "$v2" ]]
}

# Get current installed version from the installed AppImage
get_current_version() {
    if [[ ! -f "$INSTALL_PATH" ]]; then
        echo ""
        return
    fi
    
    # Extract version from the symlink target or filename
    local target=$(readlink "$INSTALL_PATH" 2>/dev/null || echo "$INSTALL_PATH")
    local filename=$(basename "$target")
    
    # Match version pattern in filename
    if [[ $filename =~ ([0-9]+\.[0-9]+\.[0-9]+) ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo ""
    fi
}

# Main execution
main() {
    log "Starting Cursor IDE update check..."
    
    local platform=$(get_platform)
    log "Platform: $platform"
    
    # Get current version
    local current_version=$(get_current_version)
    if [[ -n "$current_version" ]]; then
        log "Current version: $current_version"
    else
        log "No current installation found"
    fi
    
    # Get latest version and download URL from Cursor API
    local cursor_info=$(get_latest_cursor_info "$platform")
    if [[ $? -ne 0 ]]; then
        log "Error: Could not get latest version info from API"
        exit 1
    fi
    
    local latest_version=$(echo "$cursor_info" | cut -d'|' -f1)
    local download_url=$(echo "$cursor_info" | cut -d'|' -f2)
    log "Latest version available: $latest_version"
    
    # Compare versions if current version exists
    if [[ -n "$current_version" ]]; then
        if version_greater_than "$latest_version" "$current_version"; then
            log "Update available: $current_version -> $latest_version"
        else
            log "Already up to date. Current: $current_version, Latest: $latest_version"
            exit 0
        fi
    else
        log "No current installation found, will download latest version: $latest_version"
    fi
    
    # Download the latest version
    local filename=$(basename "$download_url")
    local temp_file="/tmp/$filename"
    
    log "Downloading $filename..."
    if ! curl -L -o "$temp_file" "$download_url"; then
        log "Error: Failed to download $filename"
        exit 1
    fi
    
    # Verify download
    if [[ ! -f "$temp_file" ]] || [[ ! -s "$temp_file" ]]; then
        log "Error: Download verification failed"
        exit 1
    fi
    
    log "Download completed successfully"
    
    # Make executable and install
    chmod +x "$temp_file"
    log "Installing to $INSTALL_PATH..."
    
    if ! sudo mv "$temp_file" "$INSTALL_PATH"; then
        log "Error: Failed to install Cursor"
        exit 1
    fi
    
    log "Cursor IDE updated successfully to version $latest_version"
    log "Please restart Cursor manually to use the new version"
}

main "$@" 