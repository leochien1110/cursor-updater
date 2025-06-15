# Changelog

All notable changes to the Cursor Updater project will be documented in this file.

## [2025-06-15] - Major API Update

### Changed
- **BREAKING**: Replaced old redirect URLs with official Cursor API endpoint
- Updated from `https://www.cursor.com/download/stable/*` to `https://www.cursor.com/api/download?platform=<platform>&releaseTrack=latest`
- Simplified installation path to fixed `/opt/cursor.appimage` location
- Improved version detection to work with current Cursor filename patterns

### Added
- Proper JSON parsing for API responses
- Semantic version comparison for reliable update detection
- Better error handling for API failures
- More reliable download URL discovery

### Fixed
- **Critical**: Fixed issue where updater couldn't find latest versions (e.g., v1.1.2)
- Fixed version detection from AppImage filenames
- Resolved 403 Forbidden errors from old API endpoints

### Improved
- Cleaned up verbose comments and unused functions
- Simplified script logic and reduced complexity
- Better logging with cleaner output
- Non-intrusive updates (doesn't stop running Cursor instances)

### Technical Details
- Now uses the same API endpoint as the [oslook/cursor-ai-downloads](https://github.com/oslook/cursor-ai-downloads) repository
- API returns JSON with exact version and download URL: `{"version":"1.1.2","downloadUrl":"https://downloads.cursor.com/production/..."}`
- Supports both x64 and arm64 Linux architectures
- Maintains backwards compatibility with existing systemd service setup

### Migration Notes
- No manual migration required - existing installations will automatically use the new API
- Daily timer and systemd service configuration remains unchanged
- Users may need to restart Cursor manually after updates (by design) 