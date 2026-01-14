#!/bin/bash
#
# install-brave-extensions.sh
#
# Opens installation pages for Brave extensions from ~/.config/dotfiles/config.yaml
#
# Note: Brave doesn't support CLI extension installation.
# This script opens the Chrome Web Store page for each extension.

set -e

# Configuration
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/config.yaml"

# Options
VERBOSE=false
DRY_RUN=false

# Colors
if [[ -t 1 ]]; then
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    NC='\033[0m'
else
    GREEN='' YELLOW='' NC=''
fi

say() { echo -e "${GREEN}[brave]${NC} $1"; }
warn() { echo -e "${YELLOW}[brave]${NC} $1"; }

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose) VERBOSE=true ;;
        --dry-run) DRY_RUN=true ;;
        -h|--help)
            echo "Usage: $0 [--verbose] [--dry-run]"
            echo ""
            echo "Opens Brave extension installation pages from config.yaml"
            echo ""
            echo "Options:"
            echo "  --verbose    Show detailed output"
            echo "  --dry-run    Preview without opening browser"
            exit 0
            ;;
        *) ;;
    esac
    shift
done

# Check if extension is already installed (macOS only)
is_extension_installed() {
    local extension_id="$1"

    if [[ "$(uname)" != "Darwin" ]]; then
        return 1
    fi

    local brave_profile_base="$HOME/Library/Application Support/BraveSoftware/Brave-Browser"

    if [[ ! -d "$brave_profile_base" ]]; then
        return 1
    fi

    # Check all profiles for the extension
    while IFS= read -r -d '' profile_dir; do
        if [[ -d "$profile_dir/Extensions/$extension_id" ]]; then
            return 0
        fi
    done < <(find "$brave_profile_base" -maxdepth 1 -type d \( -name "Default" -o -name "Profile*" \) -print0 2>/dev/null)

    return 1
}

# Open URL in Brave
open_extension_url() {
    local install_url="$1"

    if [[ "$(uname)" == "Darwin" ]]; then
        if open -Ra "Brave Browser" 2>/dev/null; then
            open -a "Brave Browser" "$install_url"
        else
            warn "Brave Browser not found, opening in default browser"
            open "$install_url"
        fi
    elif [[ "$(uname)" == "Linux" ]]; then
        if command -v brave-browser &>/dev/null; then
            brave-browser "$install_url" &
        elif command -v xdg-open &>/dev/null; then
            xdg-open "$install_url" &
        else
            warn "Could not open URL: $install_url"
            return 1
        fi
    else
        warn "Unsupported OS. Open manually: $install_url"
        return 1
    fi
}

# Check yq
if ! command -v yq &>/dev/null; then
    warn "yq not installed. Install with: brew install yq"
    exit 1
fi

# Check config file
if [[ ! -f "$CONFIG_FILE" ]]; then
    warn "Config file not found: $CONFIG_FILE"
    warn "Run 'chezmoi apply' to create it"
    exit 0
fi

say "Installing Brave extensions..."

# Get extensions from config
extensions=$(yq -r '.extensions.brave[]?' "$CONFIG_FILE" 2>/dev/null | grep -v '^null$')

if [[ -z "$extensions" ]]; then
    say "No Brave extensions defined in config.yaml"
    exit 0
fi

opened_count=0
skipped_count=0

while IFS= read -r ext_id; do
    [[ -z "$ext_id" ]] && continue

    # Check if already installed
    if is_extension_installed "$ext_id"; then
        [[ "$VERBOSE" == true ]] && echo "  ✓ $ext_id (already installed)"
        ((skipped_count++))
        continue
    fi

    install_url="https://chrome.google.com/webstore/detail/$ext_id"

    if [[ "$DRY_RUN" == true ]]; then
        echo "  → Would open: $install_url"
    else
        echo "  Opening: $ext_id"
        if open_extension_url "$install_url"; then
            ((opened_count++))
            sleep 0.5  # Prevent overwhelming the browser
        fi
    fi
done <<< "$extensions"

echo ""
if [[ "$DRY_RUN" == true ]]; then
    say "Dry run complete"
else
    say "Done: $opened_count opened, $skipped_count skipped"
fi
