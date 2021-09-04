#!/bin/sh
SCRIPTNAME="${0##*/}"

say() {
	echo $1
}

warn() {
	printf >&2 "$SCRIPTNAME: $*\n"
}

iscmd() {
	command -v "$@" >&-
}

checkdeps() {
	# https://ss64.com/bash/local.html
	local -i not_found
	for cmd; do
		say "checking if $cmd is installed"
		iscmd "$cmd" || {
			warn $"$cmd is not found"
			let not_found++
			say $not_found
		}
	done
	((not_found == 0)) || {
		warn $"Install dependencies listed above to use $SCRIPTNAME"
	}
}

installdeps() {
	say "installdeps 1"
	say "installing..."
}

main() {
	say "hello world"
	say "checking dependencies..."
	checkdeps git brew juca
	installdeps juca
}

main
