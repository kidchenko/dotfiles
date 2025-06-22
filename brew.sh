#!/usr/bin/env bash

# --- Script Configuration & Variables ---
CONFIG_FILE_NAME="config.yaml" # Name of the config file

# Determine config file path using XDG standard or fallback to HOME
if [ -n "$XDG_CONFIG_HOME" ]; then
    CONFIG_DIR="$XDG_CONFIG_HOME/dotfiles"
else
    CONFIG_DIR="$HOME/.config/dotfiles"
fi
CONFIG_FILE="$CONFIG_DIR/$CONFIG_FILE_NAME"

# --- Helper Functions ---
say() {
    echo "brew.sh: $1"
}

say_error() {
    say "ERROR: $1" >&2
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to ensure yq is installed
ensure_yq_installed() {
    if ! command_exists yq; then
        say "'yq' (YAML processor) not found. Attempting to install via Homebrew..."
        if brew install yq; then
            say "'yq' installed successfully."
        else
            say_error "Failed to install 'yq'. This script cannot proceed without it."
            say_error "Please install 'yq' manually (e.g., 'brew install yq') and re-run this script."
            exit 1
        fi
    else
        say "'yq' is already installed."
    fi
}

# --- Main Script Logic ---

# Ask for the administrator password upfront
sudo -v

# Make sure we’re using the latest Homebrew.
say "Updating Homebrew..."
brew update

# Upgrade any already-installed formulae.
say "Upgrading existing Homebrew packages..."
brew upgrade

# Save Homebrew’s installed location.
BREW_PREFIX=$(brew --prefix)
say "Homebrew prefix: $BREW_PREFIX"

# Ensure yq is available for parsing the config file
ensure_yq_installed

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    say_error "Configuration file not found at $CONFIG_FILE"
    say_error "Please ensure it exists and is populated with brew packages and casks."
    exit 1
fi

say "Reading package list from $CONFIG_FILE"

# Install standard packages (formulae)
say "Processing Homebrew packages (formulae)..."
mapfile -t brew_packages < <(yq eval '.brew.packages[]?' "$CONFIG_FILE" | grep -v '^null$')

if [ ${#brew_packages[@]} -gt 0 ]; then
    for pkg in "${brew_packages[@]}"; do
        say "Checking/installing Homebrew package: $pkg"
        install_cmd="brew install $pkg"

        # Handle packages with specific options
        # This is a simple way; a more complex YAML structure could handle arbitrary options.
        if [[ "$pkg" == "gnu-sed" ]]; then
            install_cmd="brew install gnu-sed --with-default-names"
            say "Applying specific options for gnu-sed: --with-default-names"
        elif [[ "$pkg" == "wget" ]]; then
            install_cmd="brew install wget --with-iri"
            say "Applying specific options for wget: --with-iri"
        elif [[ "$pkg" == "vim" ]]; then
            install_cmd="brew install vim --with-override-system-vi"
            say "Applying specific options for vim: --with-override-system-vi"
        elif [[ "$pkg" == "imagemagick" ]]; then
            install_cmd="brew install imagemagick --with-webp"
            say "Applying specific options for imagemagick: --with-webp"
        fi

        if $install_cmd; then
            say "$pkg installed/updated successfully."
        else
            say_error "Failed to install $pkg. Continuing with others..."
        fi
    done
else
    say "No Homebrew packages listed in $CONFIG_FILE under brew.packages"
fi

# Special handling for coreutils symlink (if coreutils was installed)
# This assumes 'coreutils' is in the package list if this functionality is desired.
if yq eval '.brew.packages[] | select(. == "coreutils")' "$CONFIG_FILE" | grep -q "coreutils"; then
    if [ -f "${BREW_PREFIX}/bin/gsha256sum" ] && [ ! -L "${BREW_PREFIX}/bin/sha256sum" ]; then
        say "Creating symlink for gsha256sum to sha256sum..."
        ln -s "${BREW_PREFIX}/bin/gsha256sum" "${BREW_PREFIX}/bin/sha256sum" || say_error "Failed to create symlink for sha256sum."
    elif [ -L "${BREW_PREFIX}/bin/sha256sum" ]; then
        say "Symlink for sha256sum already exists."
    else
        say "coreutils or gsha256sum not found, skipping sha256sum symlink."
    fi
fi

# Special handling for Zsh setup (if zsh was installed)
# This assumes 'zsh' is in the package list if this functionality is desired.
if yq eval '.brew.packages[] | select(. == "zsh")' "$CONFIG_FILE" | grep -q "zsh"; then
    say "Configuring Zsh..."
    if ! fgrep -q "${BREW_PREFIX}/bin/zsh" /etc/shells; then
        say "Adding ${BREW_PREFIX}/bin/zsh to /etc/shells"
        echo "${BREW_PREFIX}/bin/zsh" | sudo tee -a /etc/shells
    else
        say "${BREW_PREFIX}/bin/zsh already in /etc/shells"
    fi
    if [[ "$SHELL" != "${BREW_PREFIX}/bin/zsh" ]]; then
        say "Attempting to change default shell to Zsh. You might be prompted for your password."
        if chsh -s "${BREW_PREFIX}/bin/zsh"; then
            say "Default shell changed to Zsh. Please open a new terminal session for this to take effect."
        else
            say_error "Failed to change default shell to Zsh. You may need to do this manually."
        fi
    else
        say "Default shell is already ${BREW_PREFIX}/bin/zsh"
    fi
else
    say "zsh not listed in config, skipping Zsh specific setup."
fi

# Tap font repositories if any fonts are listed (example: homebrew/cask-fonts)
# This is a generic tap that many fonts use. Specific fonts might need their own taps.
# For simplicity, we'll tap common ones.
# The config.yaml has 'font-hack-nerd-font' which is in 'homebrew/cask-fonts'
# We can check if any cask starts with 'font-' and tap 'homebrew/cask-fonts'
if yq eval '.brew.casks[]?' "$CONFIG_FILE" | grep -q "^font-"; then
    say "Tapping homebrew/cask-fonts as font casks are listed..."
    brew tap homebrew/cask-fonts || say_error "Failed to tap homebrew/cask-fonts. Font installation might fail."
fi
# Example for bramstein/webfonttools if sfnt2woff etc. are listed under packages
if yq eval '.brew.packages[] | select(. == "sfnt2woff" or . == "sfnt2woff-zopfli" or . == "woff2")' "$CONFIG_FILE" | grep -q "."; then
    say "Tapping bramstein/webfonttools for font utilities..."
    brew tap bramstein/webfonttools || say_error "Failed to tap bramstein/webfonttools."
fi


# Install Casks
say "Processing Homebrew Casks..."
mapfile -t brew_casks < <(yq eval '.brew.casks[]?' "$CONFIG_FILE" | grep -v '^null$')

if [ ${#brew_casks[@]} -gt 0 ]; then
    for cask in "${brew_casks[@]}"; do
        say "Checking/installing Homebrew Cask: $cask"
        if brew install --cask "$cask"; then
            say "Cask $cask installed/updated successfully."
        else
            say_error "Failed to install Cask $cask. Continuing with others..."
        fi
    done
else
    say "No Homebrew Casks listed in $CONFIG_FILE under brew.casks"
fi

# Remove outdated versions from the cellar.
say "Cleaning up Homebrew..."
brew cleanup

say "brew.sh script finished."
