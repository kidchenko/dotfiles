#!/bin/bash

copyProfile() {
    echo "Copying profile files."
    cp ./.zshrc ~/.zshrc
    cp ./.zlogin ~/.zlogin
    cp ./.aliases ~/.aliases
    cp ./.exports ~/.exports
    cp ./.functions ~/.functions
    cp ./.gitconfig ~/.gitconfig
    cp ./.gvimrc ~/.gvimrc
    cp ./.hyper.js ~/.hyper.js
    cp ./.tmux.conf ~/.tmux.conf
    cp ./.vimrc ~/.vimrc
    cp ./brew.sh ~/brew.sh
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
    reloadProfile
}

main
