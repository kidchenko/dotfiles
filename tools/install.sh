#!/bin/sh

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
	say
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
			warn $"$cmd is not found"
			let not_found++
		}
	done
	# same as if ()
	((not_found == 0)) || {
		warn $"The dependencies listed above are required to use $SCRIPTNAME"
        say "I can install the required dependencies for you."
		ask $"Do you wanna to install? [y/n]: "
		if [[ ! $REPLY =~ ^[Yy]$ ]]; then
			say "Install the required dependencies and then try again..."
			say "bye."
			[[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
		fi

	}

}

installdeps() {
	say
	say "Installing dependencies..."
	# same as for var in "$@"
	# https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
	for dep; do
		say "installing dependency $dep."
	done
    say
}

clone() {
	rm -rf dotfiles
	git clone https://github.com/kidchenko/dotfiles.git -c core.eol=lf -c core.autocrlf=false \
    -c fsck.zeroPaddedFilemode=ignore \
    -c fetch.fsck.zeroPaddedFilemode=ignore \
    -c receive.fsck.zeroPaddedFilemode=ignore \
    --depth=1 || {
    say "git clone of dotfiles repo failed"
    exit 1
  }
  say
}

setup() {
    say "Running setup"
    pushd dotfiles > /dev/null
    source ./setup.sh
    popd > /dev/null
}

main() {
    say
	say "Installing dotfiles at ./dotfiles"

	checkdeps git brew juca
	installdeps juca
	clone
    setup
}

main
