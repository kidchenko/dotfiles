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
	printf >&2 "$SCRIPTNAME: $*\n"
}

iscmd() {
	command -v "$@" >&-
}

checkdeps() {
	say
	say "checking dependencies..."
	# https://ss64.com/bash/local.html
	local -i not_found
	for cmd; do
		say "checking if $cmd is installed"
		iscmd "$cmd" || {
			warn $"$cmd is not found"
			let not_found++
		}
	done
	# same as if ()
	((not_found == 0)) || {
		warn $"The dependencies listed above are required to use $SCRIPTNAME"
		ask $"Do you wanna to install?"
		if [[ ! $REPLY =~ ^[Yy]$ ]]; then
			say "install the dependencies and then try again..."
			say "bye."
			[[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
		fi

	}

}

installdeps() {
	say
	say "installing deps..."
	# same as for var in "$@"
	# https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
	for dep; do
		say "installing dep $dep"
	done
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

}

main() {
	say "hello world"

	checkdeps git brew juca
	installdeps juca brew
	clone
}

main
