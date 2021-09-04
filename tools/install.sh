#!/bin/sh
SCRIPTNAME="${0##*/}"

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
		echo "checking if $cmd is installed"
		iscmd "$cmd" || {
			warn $"$cmd is not found"
			let not_found++
			echo $not_found
		}
	done
	((not_found == 0)) || {
		warn $"Install dependencies listed above to use $SCRIPTNAME"
	}
}

installdeps() {
	echo "installdeps 1"
	echo "installing..."
}

main() {
	echo "hello world"
	echo "checking dependencies..."
	checkdeps git brew juca
	installdeps juca
}

main
