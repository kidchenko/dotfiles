# dotfiles defaults

Apply macOS system preferences for a developer-friendly setup.

## Usage

```bash
dotfiles defaults
```

## Platform

**macOS only.** This command is not available on Linux.

## What It Does

Runs the macOS configuration script at `tools/os_setup/macos_config.sh`.

This modifies system preferences using `defaults write` commands.

## Changes Made

### General UI/UX
- Disable boot sound
- Always show scrollbars
- Expand save/print panels by default
- Save to disk (not iCloud) by default
- Disable "Are you sure?" dialogs for apps
- Disable auto-capitalization, smart dashes, smart quotes, auto-correct

### Trackpad & Keyboard
- Enable tap to click
- Enable right-click in bottom right corner
- Full keyboard access for all controls
- Ctrl+scroll to zoom
- Disable press-and-hold for keys
- Fast keyboard repeat rate

### Energy
- Enable lid wakeup
- Auto-restart on power loss
- Display sleep: 10 min (charger), 5 min (battery)

### Screen
- Require password immediately after sleep
- Screenshots as JPG to `~/Documents/Screenshots`
- Disable screenshot shadows

### Finder
- Allow quitting Finder (Cmd+Q)
- Show hidden files
- Show file extensions
- Show status bar and path bar
- Show full POSIX path in title
- Folders on top when sorting
- Search in current folder by default
- No warning when changing extensions
- Avoid .DS_Store on network/USB
- List view by default
- Show ~/Library and /Volumes folders

### Dock
- 48px icons
- Scale minimize effect
- Minimize to app icon
- Speed up Mission Control
- Don't rearrange Spaces
- Auto-hide with no delay
- Don't show recent apps

### Hot Corners
- Top left: Lock Screen
- Top right: Mission Control
- Bottom left: Launchpad

### Terminal
- UTF-8 only
- Secure keyboard entry
- No line marks

### Time Machine
- Don't prompt for new backup disks

### Activity Monitor
- Show main window on launch
- CPU usage in Dock icon
- Show all processes

### TextEdit
- Plain text by default
- UTF-8 encoding

### App Store
- Auto-check for updates daily
- Download updates in background
- Install security updates automatically

### Photos
- Don't auto-open when devices plug in

### Chrome
- Disable swipe navigation
- Native print preview

## After Running

Some changes require:
- **Logout** to take effect
- **Restart** for full effect

The script automatically restarts affected apps (Finder, Dock, etc.).

## Review Before Running

Check the script before running:

```bash
less ~/.local/share/chezmoi/tools/os_setup/macos_config.sh
```

## Customizing

Edit `tools/os_setup/macos_config.sh` to:
- Add new settings
- Remove unwanted settings
- Change values

Example:
```bash
# Change Dock icon size to 36
defaults write com.apple.dock tilesize -int 36

# Different hot corner (4 = Desktop)
defaults write com.apple.dock wvous-tr-corner -int 4
```

## Reverting Changes

There's no automatic revert. To undo:
1. Change settings manually in System Preferences
2. Or use `defaults delete` commands

Example:
```bash
# Reset Dock to defaults
defaults delete com.apple.dock
killall Dock
```

## Related Commands

- [dotfiles doctor](doctor.md) - Check system status
- [dotfiles bootstrap](bootstrap.md) - Full setup
