#!/bin/bash

copyProfile() {
    cp ./.aliases ~/.aliases
}

main() {
    echo "hello world, I am setup"
    copyProfile
}

main
