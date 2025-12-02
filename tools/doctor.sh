#!/bin/bash
#
# doctor.sh - Health check for dotfiles and system configuration
#
# Usage:
#   ./tools/doctor.sh              # Run all checks
#   ./tools/doctor.sh --quick      # Skip slow checks (disk, outdated)
#   ./tools/doctor.sh --fix        # Attempt to fix issues
#   ./tools/doctor.sh --help       # Show help
#

# Don't use set -e as we want to continue even if checks fail

# Colors (only if terminal supports it)
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    NC='\033[0m' # No Color
else
    RED='' GREEN='' YELLOW='' BLUE='' BOLD='' NC=''
fi

# Counters
PASS=0
WARN=0
FAIL=0

# Options
QUICK=false
FIX=false

# Output helpers
pass() { echo -e "${GREEN}✓${NC} $1"; ((PASS++)); }
warn() { echo -e "${YELLOW}!${NC} $1"; ((WARN++)); }
fail() { echo -e "${RED}✗${NC} $1"; ((FAIL++)); }
info() { echo -e "${BLUE}→${NC} $1"; }
header() { echo -e "\n${BOLD}$1${NC}"; }

# Parse arguments
for arg in "$@"; do
    case $arg in
        --quick) QUICK=true ;;
        --fix) FIX=true ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --quick  Skip slow checks (disk space, outdated packages)"
            echo "  --fix    Attempt to automatically fix issues"
            echo "  --help   Show this help message"
            echo ""
            exit 0
            ;;
    esac
done

echo -e "${BOLD}Dotfiles Doctor${NC}"
echo "Running health checks..."

# =============================================================================
# Core Tools
# =============================================================================
header "Core Tools"

# Chezmoi
if command -v chezmoi >/dev/null 2>&1; then
    pass "chezmoi installed ($(chezmoi --version | head -1 | awk '{print $3}'))"
else
    fail "chezmoi not installed"
fi

# Git
if command -v git >/dev/null 2>&1; then
    pass "git installed ($(git --version | awk '{print $3}'))"
else
    fail "git not installed"
fi

# Homebrew (macOS)
if [[ "$(uname -s)" == "Darwin" ]]; then
    if command -v brew >/dev/null 2>&1; then
        pass "homebrew installed ($(brew --version | head -1 | awk '{print $2}'))"
    else
        fail "homebrew not installed"
    fi
fi

# Zsh
if command -v zsh >/dev/null 2>&1; then
    pass "zsh installed ($(zsh --version | awk '{print $2}'))"
    if [[ "$SHELL" == *"zsh"* ]]; then
        pass "zsh is default shell"
    else
        warn "zsh is not default shell (current: $SHELL)"
        if $FIX; then
            info "Run: chsh -s $(which zsh)"
        fi
    fi
else
    fail "zsh not installed"
fi

# Oh My Zsh
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    pass "oh-my-zsh installed"
else
    warn "oh-my-zsh not installed"
fi

# =============================================================================
# 1Password CLI
# =============================================================================
header "1Password CLI"

if command -v op >/dev/null 2>&1; then
    pass "1password-cli installed ($(op --version))"
    if op account list &>/dev/null; then
        pass "1password-cli authenticated"
    else
        warn "1password-cli not signed in (run: op signin)"
    fi
else
    warn "1password-cli not installed (optional, for secrets management)"
fi

# =============================================================================
# XDG Directories
# =============================================================================
header "XDG Directories"

XDG_DIRS=(
    "${XDG_CONFIG_HOME:-$HOME/.config}:XDG_CONFIG_HOME"
    "${XDG_DATA_HOME:-$HOME/.local/share}:XDG_DATA_HOME"
    "${XDG_CACHE_HOME:-$HOME/.cache}:XDG_CACHE_HOME"
    "${XDG_STATE_HOME:-$HOME/.local/state}:XDG_STATE_HOME"
    "$HOME/.local/bin:XDG_BIN_HOME"
)

for entry in "${XDG_DIRS[@]}"; do
    dir="${entry%%:*}"
    name="${entry##*:}"
    if [[ -d "$dir" ]]; then
        pass "$name exists ($dir)"
    else
        warn "$name missing ($dir)"
        if $FIX; then
            mkdir -p "$dir"
            info "Created $dir"
        fi
    fi
done

# =============================================================================
# Chezmoi State
# =============================================================================
header "Chezmoi State"

CHEZMOI_SOURCE="${XDG_DATA_HOME:-$HOME/.local/share}/chezmoi"
if [[ -d "$CHEZMOI_SOURCE" ]]; then
    pass "chezmoi source directory exists"

    # Check for uncommitted changes
    if command -v chezmoi >/dev/null 2>&1; then
        if [[ -z "$(chezmoi diff 2>/dev/null)" ]]; then
            pass "dotfiles in sync (no pending changes)"
        else
            warn "dotfiles have pending changes (run: chezmoi diff)"
        fi
    fi
else
    fail "chezmoi source directory missing ($CHEZMOI_SOURCE)"
fi

# Check chezmoi config
CHEZMOI_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/chezmoi/chezmoi.toml"
if [[ -f "$CHEZMOI_CONFIG" ]]; then
    pass "chezmoi config exists"
else
    warn "chezmoi config missing ($CHEZMOI_CONFIG)"
fi

# =============================================================================
# Shell Configuration
# =============================================================================
header "Shell Configuration"

# Zsh config files
ZSH_FILES=(
    "$HOME/.zshrc:zshrc"
    "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/aliases.sh:aliases"
    "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/exports.sh:exports"
    "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/functions.sh:functions"
)

for entry in "${ZSH_FILES[@]}"; do
    file="${entry%%:*}"
    name="${entry##*:}"
    if [[ -f "$file" ]]; then
        pass "$name exists"
    else
        warn "$name missing ($file)"
    fi
done

# Zsh plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
PLUGINS=(
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions:zsh-autosuggestions"
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting:zsh-syntax-highlighting"
    "$ZSH_CUSTOM/plugins/zsh-nvm:zsh-nvm"
)

for entry in "${PLUGINS[@]}"; do
    dir="${entry%%:*}"
    name="${entry##*:}"
    if [[ -d "$dir" ]]; then
        pass "$name plugin installed"
    else
        warn "$name plugin missing"
    fi
done

# =============================================================================
# Git Configuration
# =============================================================================
header "Git Configuration"

if git config --global user.name >/dev/null 2>&1; then
    pass "git user.name configured ($(git config --global user.name))"
else
    fail "git user.name not configured"
fi

if git config --global user.email >/dev/null 2>&1; then
    pass "git user.email configured ($(git config --global user.email))"
else
    fail "git user.email not configured"
fi

if git config --global core.editor >/dev/null 2>&1; then
    pass "git editor configured ($(git config --global core.editor))"
else
    warn "git editor not configured"
fi

# GPG signing
if git config --global commit.gpgsign >/dev/null 2>&1; then
    if git config --global user.signingkey >/dev/null 2>&1; then
        pass "git GPG signing configured"
    else
        warn "git GPG signing enabled but no key configured"
    fi
fi

# =============================================================================
# Broken Symlinks
# =============================================================================
header "Symlink Health"

SYMLINK_CHECK_DIRS=(
    "$HOME/.config"
    "$HOME/.local/bin"
    "$HOME/.local/share"
)

BROKEN_LINKS=()
for dir in "${SYMLINK_CHECK_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
        while IFS= read -r -d '' link; do
            BROKEN_LINKS+=("$link")
        done < <(find "$dir" -maxdepth 3 -type l ! -exec test -e {} \; -print0 2>/dev/null)
    fi
done

if [[ ${#BROKEN_LINKS[@]} -eq 0 ]]; then
    pass "no broken symlinks found"
else
    fail "found ${#BROKEN_LINKS[@]} broken symlink(s)"
    for link in "${BROKEN_LINKS[@]}"; do
        info "  $link -> $(readlink "$link")"
        if $FIX; then
            rm "$link"
            info "  Removed $link"
        fi
    done
fi

# =============================================================================
# Disk Space (skip with --quick)
# =============================================================================
if ! $QUICK; then
    header "Disk Space"

    if [[ "$(uname -s)" == "Darwin" ]]; then
        # macOS
        DISK_INFO=$(df -H / | tail -1)
        DISK_USED=$(echo "$DISK_INFO" | awk '{print $5}' | tr -d '%')
        DISK_AVAIL=$(echo "$DISK_INFO" | awk '{print $4}')

        if [[ $DISK_USED -lt 80 ]]; then
            pass "disk usage OK (${DISK_USED}% used, ${DISK_AVAIL} available)"
        elif [[ $DISK_USED -lt 90 ]]; then
            warn "disk usage high (${DISK_USED}% used, ${DISK_AVAIL} available)"
        else
            fail "disk usage critical (${DISK_USED}% used, ${DISK_AVAIL} available)"
        fi

        # Check common cache directories
        CACHE_SIZES=()
        for cache_dir in "$HOME/.cache" "$HOME/Library/Caches" "$HOME/.npm" "$HOME/.nuget"; do
            if [[ -d "$cache_dir" ]]; then
                size=$(du -sh "$cache_dir" 2>/dev/null | awk '{print $1}')
                CACHE_SIZES+=("$cache_dir: $size")
            fi
        done

        if [[ ${#CACHE_SIZES[@]} -gt 0 ]]; then
            info "Cache directories:"
            for cache in "${CACHE_SIZES[@]}"; do
                info "  $cache"
            done
        fi
    fi
fi

# =============================================================================
# Outdated Packages (skip with --quick)
# =============================================================================
if ! $QUICK && command -v brew >/dev/null 2>&1; then
    header "Homebrew Packages"

    OUTDATED=$(brew outdated --quiet 2>/dev/null | wc -l | tr -d ' ')
    if [[ $OUTDATED -eq 0 ]]; then
        pass "all homebrew packages up to date"
    elif [[ $OUTDATED -lt 10 ]]; then
        warn "$OUTDATED package(s) outdated (run: brew upgrade)"
    else
        warn "$OUTDATED packages outdated (run: brew upgrade)"
    fi

    # Check Brewfile sync
    CHEZMOI_SOURCE="${XDG_DATA_HOME:-$HOME/.local/share}/chezmoi"
    BREWFILE="$CHEZMOI_SOURCE/Brewfile"
    if [[ -f "$BREWFILE" ]]; then
        MISSING=$(brew bundle check --file="$BREWFILE" 2>&1 | grep -c "needs to be installed" || true)
        if [[ $MISSING -eq 0 ]]; then
            pass "all Brewfile packages installed"
        else
            warn "$MISSING Brewfile package(s) not installed (run: brew bundle install)"
            if $FIX; then
                info "Installing missing packages..."
                brew bundle install --file="$BREWFILE"
            fi
        fi
    fi
fi

# =============================================================================
# Modern CLI Tools
# =============================================================================
header "Modern CLI Tools"

CLI_TOOLS=(
    "lsd:modern ls"
    "bat:modern cat"
    "fd:modern find"
    "rg:ripgrep (modern grep)"
    "fzf:fuzzy finder"
    "delta:git diff viewer"
    "lazygit:git TUI"
    "tldr:simplified man pages"
)

for entry in "${CLI_TOOLS[@]}"; do
    cmd="${entry%%:*}"
    desc="${entry##*:}"
    if command -v "$cmd" >/dev/null 2>&1; then
        pass "$desc ($cmd)"
    else
        warn "$desc not installed ($cmd)"
    fi
done

# =============================================================================
# Development Tools
# =============================================================================
header "Development Tools"

DEV_TOOLS=(
    "node:Node.js"
    "go:Go"
    "python3:Python"
    "ruby:Ruby"
    "dotnet:.NET SDK"
)

for entry in "${DEV_TOOLS[@]}"; do
    cmd="${entry%%:*}"
    desc="${entry##*:}"
    if command -v "$cmd" >/dev/null 2>&1; then
        version=$($cmd --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
        pass "$desc installed ($version)"
    else
        info "$desc not installed (optional)"
    fi
done

# =============================================================================
# Cron Jobs (macOS)
# =============================================================================
if [[ "$(uname -s)" == "Darwin" ]]; then
    header "Scheduled Tasks"

    if crontab -l 2>/dev/null | grep -qE "cron/update\.sh"; then
        pass "brew bundle cron job configured"
    else
        warn "brew bundle cron job not configured"
        info "Run: dotfiles cron setup"
    fi

    if crontab -l 2>/dev/null | grep -qE "cron/backup\.sh"; then
        pass "backup cron job configured"
    else
        warn "backup cron job not configured"
        info "Run: dotfiles cron setup"
    fi
fi

# =============================================================================
# Summary
# =============================================================================
echo ""
echo -e "${BOLD}─────────────────────────────────────${NC}"
echo -e "${BOLD}Summary${NC}"
echo -e "${GREEN}✓ $PASS passed${NC}"
if [[ $WARN -gt 0 ]]; then
    echo -e "${YELLOW}! $WARN warnings${NC}"
fi
if [[ $FAIL -gt 0 ]]; then
    echo -e "${RED}✗ $FAIL failed${NC}"
fi
echo -e "${BOLD}─────────────────────────────────────${NC}"

# Exit with error if any failures
if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
