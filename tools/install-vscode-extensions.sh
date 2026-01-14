#!/bin/bash
#
# install-vscode-extensions.sh
#
# Installs VS Code extensions from ~/.config/dotfiles/config.yaml

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

say() { echo -e "${GREEN}[vscode]${NC} $1"; }
warn() { echo -e "${YELLOW}[vscode]${NC} $1"; }

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose) VERBOSE=true ;;
        --dry-run) DRY_RUN=true ;;
        -h|--help)
            echo "Usage: $0 [--verbose] [--dry-run]"
            echo ""
            echo "Installs VS Code extensions from config.yaml"
            echo ""
            echo "Options:"
            echo "  --verbose    Show detailed output"
            echo "  --dry-run    Preview without installing"
            exit 0
            ;;
        *) ;;
    esac
    shift
done

# Check VS Code CLI
if ! command -v code &>/dev/null; then
    warn "VS Code CLI ('code') not found in PATH"
    warn "Run 'Shell Command: Install code command in PATH' from VS Code"
    exit 0
fi

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

say "Installing VS Code extensions..."

# Get extensions from config
extensions=$(yq -r '.extensions.vscode[]?' "$CONFIG_FILE" 2>/dev/null | grep -v '^null$')

if [[ -z "$extensions" ]]; then
    say "No VS Code extensions defined in config.yaml"
    exit 0
fi

# Get installed extensions (lowercase for comparison)
installed=$(code --list-extensions | tr '[:upper:]' '[:lower:]')

installed_count=0
skipped_count=0
failed_count=0

while IFS= read -r ext_id; do
    [[ -z "$ext_id" ]] && continue

    lower_ext=$(echo "$ext_id" | tr '[:upper:]' '[:lower:]')

    # Check if already installed
    if echo "$installed" | grep -Fxq "$lower_ext"; then
        [[ "$VERBOSE" == true ]] && echo "  ✓ $ext_id (already installed)"
        ((skipped_count++))
        continue
    fi

    if [[ "$DRY_RUN" == true ]]; then
        echo "  → Would install: $ext_id"
    else
        echo -n "  Installing $ext_id... "
        if code --install-extension "$ext_id" --force &>/dev/null; then
            echo "✓"
            ((installed_count++))
        else
            echo "✗"
            ((failed_count++))
        fi
    fi
done <<< "$extensions"

echo ""
if [[ "$DRY_RUN" == true ]]; then
    say "Dry run complete"
else
    say "Done: $installed_count installed, $skipped_count skipped, $failed_count failed"
fi
