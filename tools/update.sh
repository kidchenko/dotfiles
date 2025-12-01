#!/bin/bash
#
# update.sh - Check for dotfiles updates and prompt user to apply
#
# Called on shell login via .zlogin
#

DOTFILES_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/chezmoi"

say() { echo "[dotfiles] $1"; }

# Check prerequisites
command -v chezmoi &>/dev/null || { say "chezmoi not installed"; exit 1; }
[[ -d "$DOTFILES_DIR/.git" ]] || exit 0

# Check if remote has updates
git -C "$DOTFILES_DIR" fetch --quiet 2>/dev/null
LOCAL=$(git -C "$DOTFILES_DIR" rev-parse @ 2>/dev/null)
REMOTE=$(git -C "$DOTFILES_DIR" rev-parse @{u} 2>/dev/null)

if [[ -z "$REMOTE" || "$LOCAL" == "$REMOTE" ]]; then
    say "Already up to date."
    exit 0
fi

# Prompt user
say "New version available."
read -p "[dotfiles] Would you like to update? [y/n]: " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    if chezmoi update; then
        say "Updated successfully!"
    else
        say "Update failed. Run 'chezmoi update' manually."
    fi
else
    say "Update skipped."
fi
