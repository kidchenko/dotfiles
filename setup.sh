#!/bin/bash

REPO=${REPO:-~/kidchenko/dotfiles}
# DOTFILES_DIR=${DOTFILES_DIR:-~/.${REPO}}
DOTFILES_DIR=$REPO

copyProfile() {
    echo "Copying profile files."
    # cp ./tools/update.sh ~/.kidchenko/dotfiles/tools/update.sh
    cp $DOTFILES_DIR/.zshrc ~/.zshrc
    cp $DOTFILES_DIR/.zlogin ~/.zlogin
    cp $DOTFILES_DIR/.aliases ~/.aliases
    cp $DOTFILES_DIR/.exports ~/.exports
    cp $DOTFILES_DIR/.functions ~/.functions
    cp $DOTFILES_DIR/.gitconfig ~/.gitconfig
    cp $DOTFILES_DIR/.gvimrc ~/.gvimrc
    cp $DOTFILES_DIR/.hyper.js ~/.hyper.js
    cp $DOTFILES_DIR/.tmux.conf ~/.tmux.conf
    cp $DOTFILES_DIR/.vimrc ~/.vimrc
    cp $DOTFILES_DIR/brew.sh ~/brew.sh
    echo
}

ensureFolders() {

    [[ ! -s ~/lambda3 ]] && echo "~/lambda3 folder does not exist. Creating..." && mkdir ~/lambda3
    echo

    [[ ! -s ~/jetabroad ]] && echo "~/jetabroad folder does not exist. Creating..." && mkdir ~/jetabroad
    echo

    [[ ! -s ~/thoughtworks ]] && echo "~/thoughtworks folder does not exist. Creating..." && mkdir ~/thoughtworks
    echo

    [[ ! -s ~/sevenpeaks ]] && echo "~/sevenpeaks folder does not exist. Creating..." && mkdir ~/sevenpeaks
    echo

    [[ ! -s ~/isho ]] && echo "~/isho folder does not exist. Creating..." && mkdir ~/isho
    echo

    [[ ! -s ~/kidchenko ]] && echo "~/kidchenko folder does not exist. Creating..." && mkdir ~/kidchenko
    echo
}

reloadProfile() {
    echo "Reloading: ${SHELL}."
    echo "Loading user profile: ~/.zshrc"
    echo
    exec ${SHELL} -l
}

main() {
    copyProfile
    ensureFolders
    reloadProfile
}

main
