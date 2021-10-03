#!/bin/sh
echo "i am update"
# Default settings
REPO=${REPO:-kidchenko/dotfiles}
DOTFILES_DIR=${DOTFILES_DIR:-~/.${REPO}}
REMOTE=${REMOTE:-https://github.com/${REPO}.git}
BRANCH=${BRANCH:-master}

main() {
    echo
    pushd $DOTFILES_DIR > /dev/null

    # check for updates
    fetch=$(git fetch --dry-run 2>&1)

    if !(test -z "$fetch"); then
        echo "[dotfiles] New version available."
        read -p $"[dotfiles] Would you like to update? [y/n]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "[dotfiles] Updating..."
            echo
            git pull -r
            source $DOTFILES_DIR/setup.sh
        fi
    fi

    popd > /dev/null
}

main
