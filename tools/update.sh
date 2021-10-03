# Default settings
REPO=${REPO:-kidchenko/dotfiles}
DOTFILES_DIR=${DOTFILES_DIR:-~/.${REPO}}

runUpdate() {
    echo "[dotfiles] New version available."
    read -p $"[dotfiles] Would you like to update? [y/n]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "[dotfiles] Updating..."
        echo
        git pull -r
        popd >/dev/null
        echo "Ready to go!"
        echo
        . "$DOTFILES_DIR/setup.sh" # script ends here
    fi
}

main() {
    echo
    pushd $DOTFILES_DIR >/dev/null
    # check for updates
    local fetch=$(git fetch --dry-run 2>&1)
    if [ -z "$fetch" ]; then
        # no updates
        echo "[dotfiles] Using last version."
    else
        runUpdate
    fi

    unset fetch

}

main
