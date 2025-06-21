#!/bin/sh

# Default settings
REPO=kidchenko/dotfiles
DOTFILES_DIR=~/.kidchenko/dotfiles
REMOTE=${REMOTE:-https://github.com/${REPO}.git}
BRANCH=${BRANCH:-master}

SCRIPTNAME="${0##*/}"

# OS detection functions (copied from setup.sh, consider sourcing if scripts grow)
_OS_TYPE_INSTALL="" # Cache variable for install script

get_os_type_install() {
    if [[ -n "$_OS_TYPE_INSTALL" ]]; then
        echo "$_OS_TYPE_INSTALL"
        return
    fi

    if [[ "$(uname)" == "Darwin" ]]; then
        _OS_TYPE_INSTALL="macos"
    elif [[ "$(expr substr $(uname -s) 1 5)" == "Linux" ]]; then
        _OS_TYPE_INSTALL="linux"
    else
        _OS_TYPE_INSTALL="unknown"
    fi
    echo "$_OS_TYPE_INSTALL"
}

is_macos_install() {
    [[ "$(get_os_type_install)" == "macos" ]]
}

is_linux_install() {
    [[ "$(get_os_type_install)" == "linux" ]]
}
# End OS detection functions

say() {
	echo $1
}

ask() {
	say
	read -p "$*" -n 1 -r
	say
}

warn() {
	printf >&2 "WARNING $SCRIPTNAME: $*\n"
    say
}

iscmd() {
	command -v "$@" >&-
}

checkdeps() {
	say
	say "Checking dependencies..."
    say ""
	# https://ss64.com/bash/local.html
	local -i not_found
	for cmd; do
		say "Checking if $cmd is installed."
		iscmd "$cmd" || {
			warn $"$cmd is required and is not found."
			let not_found++
		}
	done
	# same as if ()
	((not_found == 0)) || {
		warn "The dependencies listed above are required to install and use this project."
        say "I can install the required dependencies for you."
		ask $"Do you wanna to install? [y/n]: "
		if [[ ! $REPLY =~ ^[Yy]$ ]]; then
			say "Install the required dependencies and then try again..."
			say "Bye."
			[[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
		fi

	}

}

installdeps() {
	say "Installing dependencies..."
    say
	# same as for var in "$@"
	# https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
	for dep; do
		say "Installing dependency: $dep."
	done
    say
}

clone() {
    say "Cloning dotfiles..."
    say
    # if [ -d "$DOTFILES_DIR"]; then
    #     say "$DOTFILES_DIR already exists. Skipping"
    #     # do something if the absolute directory exists
    # fi
	rm -rf $DOTFILES_DIR
	git clone $REMOTE $DOTFILES_DIR || {
    say "Fail to clone dotfiles."
    exit 1
  }
  say
}

setup() {
    say "Running setup."
    say

    chmod -x ~/.kidchenko/dotfiles/setup.sh
    source ~/.kidchenko/dotfiles/setup.sh
}

install_chezmoi() {
    say "Installing chezmoi..."
    say
    if ! iscmd chezmoi; then
        if is_macos_install; then
            say "Detected macOS. Installing chezmoi using Homebrew..."
            if iscmd brew; then
                brew install chezmoi || { say "Failed to install chezmoi using Homebrew."; exit 1; }
            else
                say "Homebrew not found. Please install Homebrew or install chezmoi manually."
                exit 1
            fi
        elif is_linux_install; then
            say "Detected Linux. Installing chezmoi from sh.chezmoi.io..."
            if iscmd curl || iscmd wget; then
                 sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin || { say "Failed to install chezmoi from script."; exit 1; }
            else
                say "curl or wget not found. Please install one of them or install chezmoi manually."
                exit 1
            fi
        else
            say "Unsupported OS for automatic chezmoi installation. Please visit https://www.chezmoi.io/install/ for manual instructions."
            exit 1
        fi
    else
        say "chezmoi is already installed."
    fi
    say
}

main() {
    say
    say "Determined OS type: $(get_os_type_install)"

	# checkdeps git brew juca
	# installdeps juca

    say "Installing dotfiles at $DOTFILES_DIR"

    install_chezmoi
    clone
    setup
}

main
