#!/usr/bin/env bash
#
# update.sh - Weekly brew bundle install
#
# Runs brew bundle install from the dotfiles Brewfile
# Logs output to ~/.local/state/dotfiles/brew-bundle.log

set -e

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
BREWFILE="$DOTFILES_DIR/Brewfile"
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
LOG_FILE="$LOG_DIR/brew-bundle.log"

# Find Homebrew (Apple Silicon or Intel Mac)
if [[ -x "/opt/homebrew/bin/brew" ]]; then
    BREW="/opt/homebrew/bin/brew"
elif [[ -x "/usr/local/bin/brew" ]]; then
    BREW="/usr/local/bin/brew"
else
    echo "ERROR: Homebrew not found" >&2
    exit 1
fi

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log "=== Starting brew bundle install ==="

# Update Homebrew first
if "$BREW" update >> "$LOG_FILE" 2>&1; then
    log "Homebrew updated"
else
    log "ERROR: Homebrew update failed"
fi

# Run brew bundle install
if "$BREW" bundle install --file="$BREWFILE" --no-lock >> "$LOG_FILE" 2>&1; then
    log "Brew bundle install completed successfully"
else
    log "ERROR: Brew bundle install failed"
fi

log "=== Finished ==="
