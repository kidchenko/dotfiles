#!/bin/bash

# tools/run_once_install-chezmoi.sh
#
# Idempotent script to install Chezmoi if it's not already installed.
# Supports Linux and macOS.

set -e # Exit immediately if a command exits with a non-zero status.

# Function to print messages
say() {
    echo "run_once_install-chezmoi.sh: $1"
}

# Check if chezmoi is already installed
if command -v chezmoi &> /dev/null; then
    say "Chezmoi is already installed at $(command -v chezmoi)."
    exit 0
fi

say "Chezmoi not found. Attempting to install..."

# Determine OS and architecture
OS="$(uname -s)"

INSTALL_DIR="$HOME/.local/bin" # Install to user's local bin directory
mkdir -p "$INSTALL_DIR"

# Add $INSTALL_DIR to PATH for the current session if not already there
case ":$PATH:" in
    *":$INSTALL_DIR:"*) ;; # Already in PATH
    *)
        say "Adding $INSTALL_DIR to PATH for current session."
        export PATH="$INSTALL_DIR:$PATH"
        ;;
esac

# Inform user about adding to PATH permanently if it's not standard
if ! grep -q "$INSTALL_DIR" ~/.profile && ! grep -q "$INSTALL_DIR" ~/.bash_profile && ! grep -q "$INSTALL_DIR" ~/.zprofile && ! grep -q "$INSTALL_DIR" ~/.bashrc && ! grep -q "$INSTALL_DIR" ~/.zshrc; then
   PROFILE_INFO_MSG="Please add $INSTALL_DIR to your PATH permanently by adding it to your shell's profile file (e.g., ~/.bashrc, ~/.zshrc, or ~/.profile)."
fi


if [ "$OS" = "Linux" ]; then
    say "Detected Linux OS."
    # Using the install script provided by chezmoi for Linux
    if command -v curl &> /dev/null; then
        say "Installing Chezmoi using curl..."
        sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$INSTALL_DIR"
    elif command -v wget &> /dev/null; then
        say "Installing Chezmoi using wget..."
        sh -c "$(wget -qO- get.chezmoi.io)" -- -b "$INSTALL_DIR"
    else
        say "Error: curl or wget is required to download Chezmoi on Linux. Please install either and try again."
        exit 1
    fi
elif [ "$OS" = "Darwin" ]; then
    say "Detected macOS."
    if command -v brew &> /dev/null; then
        say "Installing Chezmoi using Homebrew..."
        brew install chezmoi
    else
        say "Homebrew not found. Attempting to install Chezmoi from binary..."
        if command -v curl &> /dev/null; then
            say "Installing Chezmoi using curl..."
            sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$INSTALL_DIR"
        elif command -v wget &> /dev/null; then
            say "Installing Chezmoi using wget..."
            sh -c "$(wget -qO- get.chezmoi.io)" -- -b "$INSTALL_DIR"
        else
            say "Error: curl or wget is required to download Chezmoi binary on macOS if Homebrew is not used. Please install either and try again."
            exit 1
        fi
    fi
else
    say "Error: Unsupported operating system: $OS. Cannot install Chezmoi automatically."
    say "Please install Chezmoi manually from https://www.chezmoi.io/install/"
    exit 1
fi

# Verify installation
if command -v chezmoi &> /dev/null; then
    say "Chezmoi installed successfully to $(command -v chezmoi)."
    if [ -n "$PROFILE_INFO_MSG" ]; then
        say "$PROFILE_INFO_MSG"
    fi
else
    say "Error: Chezmoi installation failed."
    say "Please check the output above for errors or try installing manually from https://www.chezmoi.io/install/"
    exit 1
fi

exit 0
