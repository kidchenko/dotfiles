#!/usr/bin/env bash
#
# cleanup.sh - Weekly cleanup of brew and caches
#
# Removes old Homebrew versions and clears caches to free disk space
# and remove potentially vulnerable old package versions.
# Logs output to ~/.local/state/dotfiles/cleanup.log

set -e

# Paths
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
LOG_FILE="$LOG_DIR/cleanup.log"

# Find Homebrew (Apple Silicon or Intel Mac)
if [[ -x "/opt/homebrew/bin/brew" ]]; then
    BREW="/opt/homebrew/bin/brew"
elif [[ -x "/usr/local/bin/brew" ]]; then
    BREW="/usr/local/bin/brew"
else
    BREW=""
fi

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log "=== Starting weekly cleanup ==="

# Brew cleanup (removes old versions, keeps last 7 days)
if [[ -n "$BREW" ]]; then
    log "Running brew cleanup..."
    if "$BREW" cleanup --prune=7 >> "$LOG_FILE" 2>&1; then
        log "Brew cleanup completed"
    else
        log "WARNING: Brew cleanup had issues"
    fi
else
    log "Homebrew not found, skipping brew cleanup"
fi

# Cache cleanup
log "Cleaning caches..."

# npm cache
if [[ -d "$HOME/.npm/_cacache" ]]; then
    rm -rf "$HOME/.npm/_cacache"/* 2>/dev/null || true
    log "Cleared npm cache"
fi

# pip cache
if [[ -d "$HOME/.cache/pip" ]]; then
    rm -rf "$HOME/.cache/pip"/* 2>/dev/null || true
    log "Cleared pip cache"
fi

# Homebrew cache (macOS)
if [[ -d "$HOME/Library/Caches/Homebrew" ]]; then
    rm -rf "$HOME/Library/Caches/Homebrew"/* 2>/dev/null || true
    log "Cleared Homebrew cache"
fi

# Go module cache (if exists and is large)
if [[ -d "$HOME/go/pkg/mod/cache" ]]; then
    # Only clean if cache is older than 30 days
    find "$HOME/go/pkg/mod/cache" -type f -mtime +30 -delete 2>/dev/null || true
    log "Cleaned old Go module cache"
fi

# Docker system prune (if docker is available and running)
if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
    log "Running docker system prune..."
    docker system prune -f --volumes >> "$LOG_FILE" 2>&1 || true
    log "Docker cleanup completed"
fi

log "=== Cleanup finished ==="
