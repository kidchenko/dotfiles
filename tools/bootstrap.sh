#!/bin/bash
#
# bootstrap.sh - Bootstrap dotfiles on a new machine
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/kidchenko/dotfiles/main/tools/bootstrap.sh | bash
#   # or
#   ./tools/bootstrap.sh
#   ./tools/bootstrap.sh --dry-run    # Preview what would be installed
#   ./tools/bootstrap.sh --help       # Show help
#

set -e

DOTFILES_REPO="https://github.com/kidchenko/dotfiles.git"
DRY_RUN=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Bootstrap dotfiles on a new machine."
            echo ""
            echo "Options:"
            echo "  --dry-run    Preview what would be installed without making changes"
            echo "  --help, -h   Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                    # Full installation"
            echo "  $0 --dry-run          # Preview only"
            echo ""
            echo "For more information, see: https://github.com/kidchenko/dotfiles"
            exit 0
            ;;
    esac
done

say() { echo "[dotfiles] $1"; }
warn() { echo "[dotfiles] WARN: $1"; }
error() { echo "[dotfiles] ERROR: $1" >&2; exit 1; }

# Dry-run wrapper - executes command only if not in dry-run mode
run() {
    if [[ "$DRY_RUN" == true ]]; then
        say "DRY-RUN: $*"
    else
        "$@"
    fi
}

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
    if [[ "$DRY_RUN" == true ]]; then
        say "DRY-RUN: Would install Homebrew from https://brew.sh"
        return 0
    fi

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
        if [[ "$DRY_RUN" == true ]]; then
            say "DRY-RUN: Would install Homebrew packages (Homebrew not yet installed)"
            return 0
        fi
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
        if [[ "$DRY_RUN" == true ]]; then
            local formulae casks
            formulae=$(grep -cE "^brew " "$BREWFILE" 2>/dev/null || echo 0)
            casks=$(grep -cE "^cask " "$BREWFILE" 2>/dev/null || echo 0)
            say "DRY-RUN: Would install $formulae formulae and $casks casks from $BREWFILE"
            return 0
        fi
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
    if [[ "$DRY_RUN" == true ]]; then
        say "DRY-RUN: Would install chezmoi from https://chezmoi.io"
        return 0
    fi

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
    if [[ "$DRY_RUN" == true ]]; then
        say "DRY-RUN: Would install Oh My Zsh from https://ohmyz.sh"
        return 0
    fi

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
        warn "Oh My Zsh installation may have failed"
    fi
}

# Install zsh plugins
install_zsh_plugins() {
    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    if [[ "$DRY_RUN" == true ]]; then
        say "DRY-RUN: Would install zsh plugins:"
        say "  - zsh-autosuggestions"
        say "  - zsh-syntax-highlighting"
        say "  - zsh-nvm"
        return 0
    fi

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
    if [[ "$DRY_RUN" == true ]]; then
        say "DRY-RUN: Would clone $DOTFILES_REPO and apply dotfiles via chezmoi"
        return 0
    fi
    chezmoi init --apply "$DOTFILES_REPO"
    say "Dotfiles applied successfully!"
}

# Setup cron jobs
setup_cron() {
    if [[ "$(uname -s)" != "Darwin" ]]; then
        say "Skipping cron setup (not macOS)"
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        say "DRY-RUN: Would setup cron jobs for Homebrew updates and backups"
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

# Setup 1Password CLI (required for secrets in chezmoi templates)
setup_1password_cli() {
    if ! command -v op >/dev/null 2>&1; then
        say "1Password CLI not installed yet (will be installed with Brewfile)"
        return 0
    fi

    # Check if already signed in
    if op account list &>/dev/null; then
        say "1Password CLI already configured"
        return 0
    fi

    say "1Password CLI detected. Sign in to enable secrets in dotfiles."
    say "Run 'op signin' manually after bootstrap, then 'chezmoi apply' again."
}

# Setup SSH keys (generate if not in 1Password, or restore from 1Password)
setup_ssh_keys() {
    # Skip if no SSH directory and no 1Password
    if [[ ! -d "$HOME/.ssh" ]] && ! command -v op >/dev/null 2>&1; then
        say "Skipping SSH setup (no 1Password CLI)"
        return 0
    fi

    # If SSH key already exists locally, skip
    if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
        say "SSH key already exists"
        return 0
    fi

    # If 1Password is signed in, check if key exists there
    if command -v op >/dev/null 2>&1 && op account list &>/dev/null; then
        if op item get "SSH Key" --vault development &>/dev/null; then
            say "SSH key found in 1Password (will be restored by chezmoi apply)"
            return 0
        fi
    fi

    # No SSH key anywhere - offer to generate one
    say "No SSH key found."
    echo ""
    read -rp "Generate SSH key and store in 1Password? [y/N]: " generate_key

    if [[ "$generate_key" == "y" || "$generate_key" == "Y" ]]; then
        local CHEZMOI_SOURCE="${XDG_DATA_HOME:-$HOME/.local/share}/chezmoi"
        local SSH_SCRIPT="$CHEZMOI_SOURCE/tools/setup-ssh-keys.sh"

        if [[ -f "$SSH_SCRIPT" ]]; then
            bash "$SSH_SCRIPT"
        else
            say "SSH setup script not found. Run 'dotfiles ssh' after bootstrap."
        fi
    else
        say "Skipping SSH key generation. Run 'dotfiles ssh' later to set up."
    fi
}

# Setup dotfiles CLI command
setup_dotfiles_cli() {
    local CHEZMOI_SOURCE="${XDG_DATA_HOME:-$HOME/.local/share}/chezmoi"
    local BIN_DIR="$HOME/.local/bin"
    local CLI_SOURCE="$CHEZMOI_SOURCE/tools/dotfiles"
    local CLI_TARGET="$BIN_DIR/dotfiles"

    if [[ ! -f "$CLI_SOURCE" ]]; then
        say "Skipping dotfiles CLI (not found in source)"
        return 0
    fi

    mkdir -p "$BIN_DIR"
    ln -sf "$CLI_SOURCE" "$CLI_TARGET"
    say "dotfiles CLI installed (run 'dotfiles help' for usage)"
}

# Main
main() {
    echo
    if [[ "$DRY_RUN" == true ]]; then
        say "Starting dotfiles bootstrap (DRY-RUN MODE)..."
        say "No changes will be made to your system."
    else
        say "Starting dotfiles bootstrap..."
    fi
    echo

    install_homebrew
    install_chezmoi
    install_brew_packages      # Moved before apply_dotfiles (installs 1password-cli)
    setup_1password_cli        # Prompt user to sign in if needed
    setup_ssh_keys             # Generate or restore SSH keys
    apply_dotfiles             # Now 1password-cli is available for templates
    install_oh_my_zsh
    install_zsh_plugins
    setup_cron
    setup_dotfiles_cli         # Install dotfiles CLI command

    echo
    if [[ "$DRY_RUN" == true ]]; then
        say "DRY-RUN complete!"
        say "Run without --dry-run to perform actual installation."
    else
        say "Bootstrap complete!"
        say "Restart your shell for all changes to take effect."
        say "Run 'dotfiles doctor' to verify your setup."
    fi
    echo
}

main "$@"
