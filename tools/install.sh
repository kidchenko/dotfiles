#!/bin/bash

# Default settings
REPO=kidchenko/dotfiles
DOTFILES_DIR=~/.kidchenko/dotfiles
REMOTE=${REMOTE:-https://github.com/${REPO}.git}
BRANCH=${BRANCH:-master}

# OS detection functions (copied from setup.sh, consider sourcing if scripts grow)
_OS_TYPE_INSTALL="" # Cache variable for install script

get_os_type_install() {
    if [[ -n "$_OS_TYPE_INSTALL" ]]; then
        printf '%s\n' "$_OS_TYPE_INSTALL"
        return
    fi

    # SC2046: Quote this to prevent word splitting
    local local_uname_s
    local_uname_s=$(uname -s)
    if [[ "$(uname)" == "Darwin" ]]; then
        _OS_TYPE_INSTALL="macos"
    elif [[ "${local_uname_s:0:5}" == "Linux" ]]; then # Bash specific string manipulation
        _OS_TYPE_INSTALL="linux"
    else
        _OS_TYPE_INSTALL="unknown"
    fi
    printf '%s\n' "$_OS_TYPE_INSTALL"
}

is_macos_install() {
    [[ "$(get_os_type_install)" == "macos" ]]
}

is_linux_install() {
    [[ "$(get_os_type_install)" == "linux" ]]
}
# End OS detection functions

say() {
    # SC2086: Double quote to prevent globbing and word splitting.
	printf '%s\n' "$1"
}

iscmd() {
    # No change needed, command -v is fine. ">&-" redirects stdout to null.
	command -v "$@" >/dev/null 2>&1
}

clone() {
    say "Cloning dotfiles..."
    say ""
    # if [ -d "$DOTFILES_DIR"]; then # Typo: missing space before ]
    #     say "$DOTFILES_DIR already exists. Skipping"
    #     # do something if the absolute directory exists
    # fi
    # Consider expanding ~ for DOTFILES_DIR if it's not already
    local expanded_dotfiles_dir
    expanded_dotfiles_dir=$(eval echo "$DOTFILES_DIR")

	rm -rf "$expanded_dotfiles_dir"
    # SC2086: Double quote to prevent globbing and word splitting.
	git clone -b "$BRANCH" --single-branch "$REMOTE" "$expanded_dotfiles_dir" || {
    say "Fail to clone dotfiles."
    exit 1
  }
  say ""
}

setup() {
    say "Running setup."
    say ""

    local setup_script_path
    # SC2088: Tilde does not expand in quotes. Use $HOME.
    setup_script_path="$HOME/.kidchenko/dotfiles/setup.sh"

    chmod +x "$setup_script_path" # Changed from -x to +x, assuming it needs to be executable to be sourced or run
    # SC3046: In POSIX sh, 'source' in place of '.' is undefined. (Fine in bash)
    # SC1090: ShellCheck can't follow non-constant source.
    # Using eval to expand tilde.
    # shellcheck source=/dev/null
    source "$setup_script_path"
}

install_chezmoi() {
    say "Installing chezmoi..."
    say ""
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
                 # SC2046: Quote this to prevent word splitting is not an issue here as we want word splitting for sh -c
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
    say ""
}

main() {
    say ""
    say "Determined OS type: $(get_os_type_install)" # Subshell output is fine here

    say "Installing dotfiles at $DOTFILES_DIR"

    install_chezmoi
    clone
    setup
}

main
