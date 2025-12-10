#!/bin/bash

# tools/install-brave-extensions.sh
#
# Opens installation pages for Brave/Chrome extensions listed in
# ~/.config/dotfiles/brave-extensions.txt (or $XDG_CONFIG_HOME/dotfiles/brave-extensions.txt).
#
# Note: Unlike VS Code, Brave doesn't support CLI extension installation.
# This script opens the Chrome Web Store page for each extension.

set -e

# --- Script Configuration & Variables ---
VERBOSE=false
DRY_RUN=false
EXTENSIONS_FILE_NAME="brave-extensions.txt"

# Determine extensions file path using XDG standard
if [ -n "$XDG_CONFIG_HOME" ]; then
    CONFIG_DIR="$XDG_CONFIG_HOME/dotfiles"
else
    CONFIG_DIR="$HOME/.config/dotfiles"
fi
EXTENSIONS_FILE="$CONFIG_DIR/$EXTENSIONS_FILE_NAME"

# --- Helper Functions ---
say() {
    echo "install-brave-extensions: $1"
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

# Check if extension is already installed in Brave (macOS only)
is_extension_installed() {
    local extension_id="$1"

    if [[ "$(uname)" != "Darwin" ]]; then
        # Can't easily check on Linux, assume not installed
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

# Open URL in appropriate browser
open_extension_url() {
    local install_url="$1"

    if [[ "$(uname)" == "Darwin" ]]; then
        if command -v open &>/dev/null && open -Ra "Brave Browser" 2>/dev/null; then
            open -a "Brave Browser" "$install_url"
        else
            say_warning "'Brave Browser' not found. Opening in default browser."
            open "$install_url"
        fi
    elif [[ "$(uname)" == "Linux" ]]; then
        if command -v brave-browser &>/dev/null; then
            brave-browser "$install_url" &
        elif command -v xdg-open &>/dev/null; then
            xdg-open "$install_url" &
        else
            say_error "Could not find 'brave-browser' or 'xdg-open' to open the URL."
            say_error "Please open manually: $install_url"
            return 1
        fi
    else
        say_warning "Unsupported OS: $(uname). Please open manually: $install_url"
        return 1
    fi
}

# --- Main Logic ---
main() {
    say "Starting Brave extension installation..."

    if [ ! -f "$EXTENSIONS_FILE" ]; then
        say_warning "Extensions file not found: $EXTENSIONS_FILE"
        say_warning "Run 'chezmoi apply' first to create the extensions file."
        exit 0
    fi

    local opened_count=0
    local skipped_count=0
    local total_count=0

    # Read extensions from file, filter out comments and empty lines
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Trim leading/trailing whitespace
        local trimmed_line
        trimmed_line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        # Skip empty lines and lines starting with #
        if [ -z "$trimmed_line" ] || [[ "$trimmed_line" == \#* ]]; then
            continue
        fi

        # Extract extension ID (part before any # comment)
        local extension_id
        extension_id=$(echo "$trimmed_line" | awk -F'#' '{print $1}' | sed 's/[[:space:]]*$//')

        if [ -z "$extension_id" ]; then
            continue
        fi

        ((total_count++))

        # Check if already installed
        if is_extension_installed "$extension_id"; then
            say_verbose "Extension '$extension_id' is already installed. Skipping."
            ((skipped_count++))
            continue
        fi

        local install_url="https://chrome.google.com/webstore/detail/$extension_id"

        if [ "$DRY_RUN" = true ]; then
            say "DRY RUN: Would open $install_url"
        else
            say "Opening install page for: $extension_id"
            if open_extension_url "$install_url"; then
                ((opened_count++))
                # Small delay to prevent overwhelming the browser
                sleep 0.5
            fi
        fi
    done < "$EXTENSIONS_FILE"

    say "Brave extension installation process finished."
    say "Summary: Processed $total_count extensions."
    if [ "$DRY_RUN" = true ]; then
        local would_open=$((total_count - skipped_count))
        say "DRY RUN MODE: Would open $would_open extension pages. $skipped_count already installed."
    else
        say "  Opened: $opened_count"
        say "  Skipped (already installed): $skipped_count"
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
            echo "  --dry-run    Simulate without opening browser tabs."
            echo "  -h, --help   Show this help message."
            echo ""
            echo "This script opens Brave extension installation pages based on $EXTENSIONS_FILE."
            exit 0
            ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
done

# --- Script Execution ---
main "$@"
