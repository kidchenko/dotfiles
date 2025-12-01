#!/bin/bash
#
# bootstrap.sh - Bootstrap dotfiles on a new machine
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/kidchenko/dotfiles/main/tools/bootstrap.sh | bash
#   # or
#   ./tools/bootstrap.sh
#

set -e

DOTFILES_REPO="https://github.com/kidchenko/dotfiles.git"

say() { echo "[dotfiles] $1"; }
error() { echo "[dotfiles] ERROR: $1" >&2; exit 1; }

# Handle curl-based execution - chezmoi init handles cloning
if [[ ! -f "${BASH_SOURCE[0]}" ]] || [[ "${BASH_SOURCE[0]}" == "environment" ]]; then
    say "Running via curl..."
fi

# Check dependencies
command -v git >/dev/null 2>&1 || error "git is required but not installed"
command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1 || error "curl or wget is required"

# Install chezmoi if not present
install_chezmoi() {
    if command -v chezmoi >/dev/null 2>&1; then
        say "chezmoi already installed: $(command -v chezmoi)"
        return 0
    fi

    say "Installing chezmoi..."
    mkdir -p "$HOME/.local/bin"

    if command -v brew >/dev/null 2>&1; then
        brew install chezmoi
    else
        sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
        export PATH="$HOME/.local/bin:$PATH"
    fi

    command -v chezmoi >/dev/null 2>&1 || error "Failed to install chezmoi"
    say "chezmoi installed successfully"
}

# Initialize and apply dotfiles
apply_dotfiles() {
    say "Initializing and applying dotfiles..."
    chezmoi init --apply "$DOTFILES_REPO"
    say "Dotfiles applied successfully!"
}

# Main
main() {
    echo
    say "Starting dotfiles bootstrap..."
    echo

    install_chezmoi
    apply_dotfiles

    echo
    say "Bootstrap complete!"
    say "Restart your shell for all changes to take effect."
    echo
}

main "$@"
