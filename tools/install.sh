#!/bin/sh

# Default settings
REPO=kidchenko/dotfiles
DOTFILES_DIR="~/.kidchenko/dotfiles"
REMOTE=${REMOTE:-https://github.com/${REPO}.git}
BRANCH=${BRANCH:-master}

SCRIPTNAME="${0##*/}"

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
    source $DOTFILES_DIR/setup.sh
}

main() {
    say

	# checkdeps git brew juca
	# installdeps juca

    say "Installing dotfiles at $DOTFILES_DIR"

    clone
    setup
}

main
