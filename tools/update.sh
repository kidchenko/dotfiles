#!/bin/bash

# Default settings
DOTFILES_DIR=~/.kidchenko/dotfiles

runUpdate() {
    echo "[dotfiles] New version available."
    read -p $"[dotfiles] Would you like to update? [y/n]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "[dotfiles] Updating..."
        echo
        git pull -r
        popd >/dev/null || exit
        echo "Ready to go!"
        echo
        # . "$DOTFILES_DIR/setup.sh" # script ends here - setup.sh is removed by bootstrap.sh
        # Consider re-running parts of bootstrap.sh or `chezmoi apply` if configurations need to be reapplied after update.
    fi
}

main() {
    echo
    pushd $DOTFILES_DIR >/dev/null || exit
    # check for updates
    local fetch
    
    fetch=$(git fetch --dry-run 2>&1)
    if [ -z "$fetch" ]; then
        # no updates
        popd >/dev/null || exit
        echo "[dotfiles] Using last version."
        echo
    else
        unset fetch
        runUpdate # warning, script finish here
    fi
}

main
