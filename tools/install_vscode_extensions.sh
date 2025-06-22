#!/bin/bash

# tools/install_vscode_extensions.sh
#
# Installs VS Code extensions listed in
# ~/.config/dotfiles/vscode-extensions.txt (or $XDG_CONFIG_HOME/dotfiles/vscode-extensions.txt).

set -e # Exit on any error

# --- Script Configuration & Variables ---
VERBOSE=false
DRY_RUN=false
EXTENSIONS_FILE_NAME="vscode-extensions.txt"

# Determine extensions file path using XDG standard
if [ -n "$XDG_CONFIG_HOME" ]; then
    CONFIG_DIR="$XDG_CONFIG_HOME/dotfiles"
else
    CONFIG_DIR="$HOME/.config/dotfiles"
fi
EXTENSIONS_FILE="$CONFIG_DIR/$EXTENSIONS_FILE_NAME"

# --- Helper Functions ---
say() {
    echo "install_vscode_extensions: $1"
}

say_verbose() {
    if [ "$VERBOSE" = true ]; then
        say "$1"
    fi
}

say_warning() {
    say "WARNING: $1"
}

say_error() {
    say "ERROR: $1" >&2
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# --- Main Logic ---
main() {
    say "Starting VS Code extension installation..."

    if ! command_exists code; then
        say_warning "VS Code CLI ('code') not found in PATH. Skipping extension installation."
        say_warning "Please ensure VS Code is installed and 'Shell Command: Install \"code\" command in PATH' has been run from VS Code."
        exit 0 # Not a fatal error for the whole bootstrap, just skip this part.
    fi

    if [ ! -f "$EXTENSIONS_FILE" ]; then
        say_warning "Extensions file not found: $EXTENSIONS_FILE"
        say_warning "Skipping VS Code extension installation."
        exit 0 # Also not fatal if file is missing.
    fi

    # Get list of already installed extensions
    # `code --list-extensions` returns a list of lowercase extension IDs.
    local installed_extensions
    installed_extensions=$(code --list-extensions | tr '[:upper:]' '[:lower:]')

    local installed_count=0
    local skipped_count=0
    local to_install_count=0
    local failed_count=0

    # Read extensions from file, filter out comments and empty lines
    mapfile -t extension_ids < <(grep -vE '^\s*#|^\s*$' "$EXTENSIONS_FILE")

    if [ ${#extension_ids[@]} -eq 0 ]; then
        say_verbose "No extensions listed in $EXTENSIONS_FILE (or all are comments/empty)."
        say "VS Code extension installation process finished. No extensions to process."
        exit 0
    fi

    to_install_count=${#extension_ids[@]}
    say_verbose "Found $to_install_count extensions to process from $EXTENSIONS_FILE."

    for ext_id in "${extension_ids[@]}"; do
        local lower_ext_id
        lower_ext_id=$(echo "$ext_id" | tr '[:upper:]' '[:lower:]') # Normalize to lowercase for comparison

        # Check if already installed (idempotency)
        if echo "$installed_extensions" | grep -Fxq "$lower_ext_id"; then
            say_verbose "Extension '$ext_id' ($lower_ext_id) is already installed. Skipping."
            ((skipped_count++))
            continue
        fi

        if [ "$DRY_RUN" = true ]; then
            say "DRY RUN: Would install VS Code extension: $ext_id (code --install-extension $ext_id)"
        else
            say "Installing VS Code extension: $ext_id..."
            if code --install-extension "$ext_id"; then # Pass original case ext_id to VS Code
                say_verbose "Extension '$ext_id' installed successfully."
                ((installed_count++))
            else
                say_error "Failed to install extension '$ext_id'."
                ((failed_count++))
                # Non-fatal, continue with other extensions
            fi
        fi
    done

    say "VS Code extension installation process finished."
    say "Summary: Processed $to_install_count extensions."
    if [ "$DRY_RUN" = true ]; then
        local would_install=$((to_install_count - skipped_count))
        say "DRY RUN MODE: Would attempt to install $would_install extensions. $skipped_count were already 'installed'."
    else
        say "  Installed: $installed_count"
        say "  Skipped (already installed): $skipped_count"
        say "  Failed: $failed_count"
    fi

    if [ $failed_count -gt 0 ]; then
        say_warning "$failed_count extensions failed to install. Check logs above."
    fi
}

# --- Argument Parsing ---
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --verbose) VERBOSE=true; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        -h|--help)
            echo "Usage: $0 [--verbose] [--dry-run]"
            echo "  --verbose    Enable verbose output."
            echo "  --dry-run    Simulate installations without making changes."
            echo "  -h, --help   Show this help message."
            echo ""
            echo "This script installs VS Code extensions based on $EXTENSIONS_FILE."
            exit 0
            ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
done

# --- Script Execution ---
main "$@"
