#!/bin/bash

copyProfile() {
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
}

main() {
    echo "hello world, I am setup"
    copyProfile
    reload
}

main
