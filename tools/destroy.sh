#!/bin/bash
#
# destroy.sh - Remove all managed dotfiles and chezmoi state
#
# Usage:
#   ./tools/destroy.sh              # Remove dotfiles only
#   ./tools/destroy.sh --all        # Remove dotfiles + chezmoi/zsh state
#   ./tools/destroy.sh --deep       # Factory reset: remove all dev tools & caches
#   ./tools/destroy.sh --force      # Skip confirmation
#   ./tools/destroy.sh --help       # Show help
#

set -e

say() { echo "[dotfiles] $1"; }
warn() { echo "[dotfiles] WARN: $1"; }
error() { echo "[dotfiles] ERROR: $1" >&2; exit 1; }

FORCE=false
CLEAN_ALL=false
DEEP_CLEAN=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --force) FORCE=true ;;
        --all) CLEAN_ALL=true ;;
        --deep) DEEP_CLEAN=true; CLEAN_ALL=true ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --force  Skip confirmation prompts"
            echo "  --all    Remove dotfiles + chezmoi state + zsh data + brew packages"
            echo "  --deep   Factory reset: remove all dev tools, caches, histories"
            echo "           WARNING: This removes npm, cargo, gems, etc."
            echo ""
            exit 0
            ;;
    esac
done

# Check if chezmoi is installed
if ! command -v chezmoi >/dev/null 2>&1; then
    error "chezmoi is not installed, nothing to destroy"
fi

# Directories to clean (managed by dotfiles)
# shellcheck disable=SC2034  # Used via nameref in show_dirs/remove_dirs
DOTFILES_DIRS=(
    "${XDG_DATA_HOME:-$HOME/.local/share}/chezmoi:chezmoi source"
    "${XDG_CONFIG_HOME:-$HOME/.config}/chezmoi:chezmoi config"
    "${XDG_CACHE_HOME:-$HOME/.cache}/chezmoi:chezmoi cache"
    "${XDG_DATA_HOME:-$HOME/.local/share}/zsh:zsh data/history"
    "${XDG_CACHE_HOME:-$HOME/.cache}/zsh:zsh cache"
    "${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles:dotfiles config"
)

# Additional dirs for deep clean (dev tools, shells, etc.)
# shellcheck disable=SC2034  # Used via nameref in show_dirs/remove_dirs
DEEP_CLEAN_DIRS=(
    "$HOME/.oh-my-zsh:Oh My Zsh"
    "$HOME/.zsh_history:zsh history (legacy)"
    "$HOME/.zcompdump*:zsh completion cache"
    "$HOME/.zsh_sessions:zsh sessions (macOS)"
    "$HOME/.bash_history:bash history"
    "$HOME/.bash_sessions:bash sessions (macOS)"
    "$HOME/.node_repl_history:node REPL history"
    "$HOME/.python_history:python history"
    "$HOME/.irb_history:ruby IRB history"
    "$HOME/.lesshst:less history"
    "$HOME/.wget-hsts:wget HSTS cache"
    "$HOME/.viminfo:vim info/history"
    "$HOME/.npm:npm cache"
    "$HOME/.yarn:yarn cache"
    "$HOME/.pnpm:pnpm cache"
    "$HOME/.nuget:nuget cache"
    "$HOME/.dotnet:dotnet tools/cache"
    "$HOME/.cargo:rust cargo"
    "$HOME/.rustup:rust toolchains"
    "$HOME/.gem:ruby gems"
    "$HOME/.bundle:ruby bundler"
    "$HOME/.composer:php composer"
    "$HOME/.gradle:gradle cache"
    "$HOME/.m2:maven cache"
    "$HOME/.cache:XDG cache (all apps)"
    "$HOME/.local/share:XDG data (all apps)"
    "$HOME/.local/state:XDG state (all apps)"
)

# Show directories from array that exist
show_dirs() {
    local arr_name=$1
    local -n arr_ref="$arr_name"  # nameref for array
    for entry in "${arr_ref[@]}"; do
        local path="${entry%%:*}"
        local desc="${entry##*:}"
        # Handle glob patterns
        for expanded in $path; do
            [[ -e "$expanded" ]] && echo "  $expanded ($desc)"
        done
    done
}

# Show what will be removed
show_managed() {
    say "The following managed files will be removed:"
    echo
    chezmoi managed 2>/dev/null | while read -r file; do
        echo "  ~/$file"
    done
    echo

    if [[ "$CLEAN_ALL" == true ]]; then
        say "Additional directories to clean (--all):"
        echo
        show_dirs DOTFILES_DIRS
        echo
    fi

    if [[ "$DEEP_CLEAN" == true ]]; then
        say "Deep clean directories (--deep):"
        warn "This will remove dev tools, package managers, and all caches!"
        echo
        show_dirs DEEP_CLEAN_DIRS
        echo
    fi
}

# Remove a directory if it exists
remove_dir() {
    local dir="$1"
    local desc="$2"
    if [[ -d "$dir" ]]; then
        rm -rf "$dir"
        echo "  Removed: $dir ($desc)"
    fi
}

# Destroy dotfiles
destroy_dotfiles() {
    say "Removing managed dotfiles..."

    # Remove managed files (not directories) from home
    chezmoi managed 2>/dev/null | while read -r file; do
        target="$HOME/$file"
        if [[ -f "$target" ]]; then
            rm -f "$target"
            echo "  Removed: ~/$file"
        fi
    done

    # Remove empty directories left behind (deepest first)
    chezmoi managed 2>/dev/null | sort -r | while read -r file; do
        target="$HOME/$file"
        if [[ -d "$target" ]]; then
            rmdir "$target" 2>/dev/null && echo "  Removed dir: ~/$file" || true
        fi
    done

    say "Managed files removed!"
}

# Remove directories from array
remove_dirs() {
    local arr_name=$1
    local -n arr_ref="$arr_name"  # nameref for array
    for entry in "${arr_ref[@]}"; do
        local path="${entry%%:*}"
        local desc="${entry##*:}"
        # Handle glob patterns
        for expanded in $path; do
            if [[ -e "$expanded" ]]; then
                rm -rf "$expanded"
                echo "  Removed: $expanded ($desc)"
            fi
        done
    done
}

# Clean additional directories
clean_all() {
    say "Cleaning dotfiles-related directories..."
    remove_dirs DOTFILES_DIRS
    say "Additional cleanup complete!"
}

# Deep clean - factory reset
deep_clean() {
    say "Deep cleaning dev tools and caches..."
    remove_dirs DEEP_CLEAN_DIRS
    say "Deep clean complete!"
}

# Uninstall Homebrew packages declared in Brewfile
uninstall_brew_packages() {
    if ! command -v brew >/dev/null 2>&1; then
        say "Skipping Homebrew packages (Homebrew not installed)"
        return 0
    fi

    # Find Brewfile
    local CHEZMOI_SOURCE="${XDG_DATA_HOME:-$HOME/.local/share}/chezmoi"
    local BREWFILE="$CHEZMOI_SOURCE/Brewfile"

    if [[ ! -f "$BREWFILE" ]]; then
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        BREWFILE="$(dirname "$SCRIPT_DIR")/Brewfile"
    fi

    if [[ ! -f "$BREWFILE" ]]; then
        say "Skipping Homebrew packages (Brewfile not found)"
        return 0
    fi

    say "Uninstalling Homebrew packages from Brewfile..."

    # Extract uncommented brew/cask lines and uninstall
    grep -E '^[^#]*(brew|cask) "' "$BREWFILE" | while read -r line; do
        local pkg
        pkg=$(echo "$line" | sed -E 's/.*"([^"]+)".*/\1/')

        if [[ "$line" =~ ^[^#]*cask ]]; then
            if brew list --cask "$pkg" &>/dev/null; then
                echo "  Uninstalling cask: $pkg"
                brew uninstall --cask "$pkg" 2>/dev/null || true
            fi
        else
            if brew list "$pkg" &>/dev/null; then
                echo "  Uninstalling formula: $pkg"
                brew uninstall "$pkg" 2>/dev/null || true
            fi
        fi
    done

    say "Homebrew packages uninstalled"
}

# Uninstall ALL Homebrew packages (for deep clean)
uninstall_all_brew() {
    if ! command -v brew >/dev/null 2>&1; then
        return 0
    fi

    say "Removing all Homebrew packages..."

    # Remove all casks
    brew list --cask 2>/dev/null | xargs -r brew uninstall --cask 2>/dev/null || true

    # Remove all formulae
    brew list --formula 2>/dev/null | xargs -r brew uninstall 2>/dev/null || true

    # Cleanup
    brew cleanup --prune=all 2>/dev/null || true

    say "All Homebrew packages removed"
}

# Purge chezmoi state
purge_chezmoi() {
    say "Purging chezmoi state..."
    chezmoi purge --force 2>/dev/null || true
    say "Chezmoi state purged!"
}

# Main
main() {
    echo
    say "Dotfiles destroy script"
    [[ "$CLEAN_ALL" == true && "$DEEP_CLEAN" != true ]] && say "Mode: Full cleanup (--all)"
    [[ "$DEEP_CLEAN" == true ]] && say "Mode: FACTORY RESET (--deep)"
    echo

    show_managed

    if [[ "$FORCE" != true ]]; then
        read -p "[dotfiles] Are you sure you want to remove all dotfiles? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            say "Aborted."
            exit 0
        fi
    fi

    destroy_dotfiles
    purge_chezmoi

    if [[ "$CLEAN_ALL" == true ]]; then
        uninstall_brew_packages
        clean_all
    fi

    if [[ "$DEEP_CLEAN" == true ]]; then
        uninstall_all_brew
        deep_clean
    fi

    echo
    say "Destroy complete!"
    say "Your dotfiles have been removed."
    [[ "$CLEAN_ALL" == true ]] && say "Chezmoi state and zsh data cleaned."
    [[ "$DEEP_CLEAN" == true ]] && say "Dev tools and caches removed (factory reset)."
    echo
}

main "$@"
