#!/bin/bash
#
# bootstrap.sh - Bootstrap dotfiles on a new machine
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/kidchenko/dotfiles/main/tools/bootstrap.sh | bash
#   # or
#   ./tools/bootstrap.sh
#

set -e

DOTFILES_REPO="https://github.com/kidchenko/dotfiles.git"

say() { echo "[dotfiles] $1"; }
error() { echo "[dotfiles] ERROR: $1" >&2; exit 1; }

# Handle curl-based execution - chezmoi init handles cloning
if [[ ! -f "${BASH_SOURCE[0]}" ]] || [[ "${BASH_SOURCE[0]}" == "environment" ]]; then
    say "Running via curl..."
fi

# Check dependencies
command -v git >/dev/null 2>&1 || error "git is required but not installed"
command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1 || error "curl or wget is required"

# Install Homebrew if not present (macOS only)
install_homebrew() {
    if command -v brew >/dev/null 2>&1; then
        say "Homebrew already installed: $(command -v brew)"
        return 0
    fi

    if [[ "$(uname -s)" != "Darwin" ]]; then
        say "Skipping Homebrew (not macOS)"
        return 0
    fi

    say "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for this session
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    command -v brew >/dev/null 2>&1 || error "Failed to install Homebrew"
    say "Homebrew installed successfully"
}

# Install Homebrew packages from Brewfile
install_brew_packages() {
    if ! command -v brew >/dev/null 2>&1; then
        say "Skipping Homebrew packages (Homebrew not installed)"
        return 0
    fi

    # Try chezmoi source directory first
    local CHEZMOI_SOURCE="${XDG_DATA_HOME:-$HOME/.local/share}/chezmoi"
    local BREWFILE="$CHEZMOI_SOURCE/Brewfile"

    # If not found, try local path (when running ./tools/bootstrap.sh directly)
    if [[ ! -f "$BREWFILE" ]]; then
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        BREWFILE="$(dirname "$SCRIPT_DIR")/Brewfile"
    fi

    if [[ -f "$BREWFILE" ]]; then
        say "Installing Homebrew packages from Brewfile..."
        brew bundle install --file="$BREWFILE"
        say "Homebrew packages installed"
    else
        say "Skipping Homebrew packages (Brewfile not found)"
    fi
}

# Install chezmoi if not present
install_chezmoi() {
    if command -v chezmoi >/dev/null 2>&1; then
        say "chezmoi already installed: $(command -v chezmoi)"
        return 0
    fi

    say "Installing chezmoi..."
    mkdir -p "$HOME/.local/bin"

    if command -v brew >/dev/null 2>&1; then
        brew install chezmoi
    else
        sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
        export PATH="$HOME/.local/bin:$PATH"
    fi

    command -v chezmoi >/dev/null 2>&1 || error "Failed to install chezmoi"
    say "chezmoi installed successfully"
}

# Install Oh My Zsh if not present
install_oh_my_zsh() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        say "Oh My Zsh already installed: $HOME/.oh-my-zsh"
        return 0
    fi

    say "Installing Oh My Zsh..."
    # RUNZSH=no prevents OMZ from launching zsh after install
    # CHSH=no prevents OMZ from changing the default shell
    export RUNZSH=no
    export CHSH=no
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true

    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        say "Oh My Zsh installed successfully"
        # Remove the .zshrc created by OMZ (we have our own)
        [[ -f "$HOME/.zshrc" ]] && rm -f "$HOME/.zshrc"
    else
        say "WARNING: Oh My Zsh installation may have failed"
    fi
}

# Install zsh plugins
install_zsh_plugins() {
    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    # zsh-autosuggestions
    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
        say "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    fi

    # zsh-syntax-highlighting
    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
        say "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    fi

    # zsh-nvm
    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-nvm" ]]; then
        say "Installing zsh-nvm..."
        git clone https://github.com/lukechilds/zsh-nvm "$ZSH_CUSTOM/plugins/zsh-nvm"
    fi

    say "Zsh plugins installed"
}

# Initialize and apply dotfiles
apply_dotfiles() {
    say "Initializing and applying dotfiles..."
    chezmoi init --apply "$DOTFILES_REPO"
    say "Dotfiles applied successfully!"
}

# Setup cron jobs
setup_cron() {
    if [[ "$(uname -s)" != "Darwin" ]]; then
        say "Skipping cron setup (not macOS)"
        return 0
    fi

    # Try chezmoi source directory first
    local CHEZMOI_SOURCE="${XDG_DATA_HOME:-$HOME/.local/share}/chezmoi"
    local CRON_SETUP="$CHEZMOI_SOURCE/cron/setup-cron.sh"

    # If not found, try local path
    if [[ ! -f "$CRON_SETUP" ]]; then
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        CRON_SETUP="$(dirname "$SCRIPT_DIR")/cron/setup-cron.sh"
    fi

    if [[ -f "$CRON_SETUP" ]]; then
        say "Setting up cron jobs..."
        bash "$CRON_SETUP"
        say "Cron jobs configured"
    else
        say "Skipping cron setup (setup-cron.sh not found)"
    fi
}

# Main
main() {
    echo
    say "Starting dotfiles bootstrap..."
    echo

    install_homebrew
    install_chezmoi
    apply_dotfiles
    install_brew_packages
    install_oh_my_zsh
    install_zsh_plugins
    setup_cron

    echo
    say "Bootstrap complete!"
    say "Restart your shell for all changes to take effect."
    echo
}

main "$@"
