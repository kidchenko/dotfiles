#!/bin/bash
#
# destroy.sh - Remove all managed dotfiles and chezmoi state
#
# Usage:
#   ./tools/destroy.sh
#   ./tools/destroy.sh --force  # Skip confirmation
#

set -e

say() { echo "[dotfiles] $1"; }
error() { echo "[dotfiles] ERROR: $1" >&2; exit 1; }

# Check if chezmoi is installed
if ! command -v chezmoi >/dev/null 2>&1; then
    error "chezmoi is not installed, nothing to destroy"
fi

# Show what will be removed
show_managed() {
    say "The following files will be removed:"
    echo
    chezmoi managed | while read -r file; do
        echo "  ~/$file"
    done
    echo
}

# Destroy dotfiles
destroy_dotfiles() {
    say "Removing managed dotfiles..."
    # Remove managed files (not directories) from home
    chezmoi managed | while read -r file; do
        target="$HOME/$file"
        if [[ -f "$target" ]]; then
            rm -f "$target"
            echo "  Removed: ~/$file"
        fi
    done

    # Remove empty directories left behind
    chezmoi managed | sort -r | while read -r file; do
        target="$HOME/$file"
        if [[ -d "$target" ]]; then
            rmdir "$target" 2>/dev/null && echo "  Removed dir: ~/$file" || true
        fi
    done
    say "Managed files removed!"

    say "Purging chezmoi state..."
    chezmoi purge --force
    say "Dotfiles removed successfully!"
}

# Main
main() {
    echo
    say "Dotfiles destroy script"
    echo

    show_managed

    if [[ "$1" != "--force" ]]; then
        read -p "[dotfiles] Are you sure you want to remove all dotfiles? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            say "Aborted."
            exit 0
        fi
    fi

    destroy_dotfiles

    echo
    say "Destroy complete!"
    say "Your dotfiles have been removed."
    echo
}

main "$@"
