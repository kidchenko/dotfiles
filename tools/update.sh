#!/bin/bash

# tools/update.sh
#
# Update script for Chezmoi-managed dotfiles
# This script checks for updates and applies them using Chezmoi

# Chezmoi source directory (where the git repo is cloned)
DOTFILES_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/chezmoi"

say() {
    echo "[dotfiles] $1"
}

runUpdate() {
    say "New version available."
    read -p $"[dotfiles] Would you like to update? [y/n]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        say "Updating..."
        echo

        # Pull changes from remote
        git pull -r
        popd >/dev/null || exit

        # Apply changes using Chezmoi
        say "Applying changes with Chezmoi..."
        if chezmoi apply --verbose; then
            say "Ready to go!"
            echo
        else
            say "ERROR: Failed to apply changes. Run 'chezmoi diff' to see what changed."
            return 1
        fi
    else
        popd >/dev/null || exit
        say "Update skipped."
    fi
}

main() {
    # Check if Chezmoi is installed
    if ! command -v chezmoi &> /dev/null; then
        say "ERROR: Chezmoi is not installed. Please install it first."
        exit 1
    fi

    # Check if dotfiles directory exists
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        say "ERROR: Dotfiles directory not found at $DOTFILES_DIR"
        say "Run 'tools/bootstrap.sh' to initialize your dotfiles."
        exit 1
    fi

    echo
    pushd "$DOTFILES_DIR" >/dev/null || exit

    # Check for updates
    local fetch
    fetch=$(git fetch --dry-run 2>&1)

    if [ -z "$fetch" ]; then
        # No updates available
        popd >/dev/null || exit
        say "Using last version."
        echo
    else
        unset fetch
        runUpdate
    fi
}

main
