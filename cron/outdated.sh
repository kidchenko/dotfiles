#!/usr/bin/env bash
#
# outdated.sh - Daily check for outdated packages
#
# Checks for outdated Homebrew packages and logs them.
# This helps catch security updates early.
# Logs output to ~/.local/state/dotfiles/outdated.log

set -e

# Paths
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
LOG_FILE="$LOG_DIR/outdated.log"

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

log "=== Checking for outdated packages ==="

# Check Homebrew packages
if [[ -n "$BREW" ]]; then
    log "Checking Homebrew packages..."

    # Get outdated packages (formulas)
    OUTDATED_FORMULAS=$("$BREW" outdated --formula 2>/dev/null || true)
    if [[ -n "$OUTDATED_FORMULAS" ]]; then
        FORMULA_COUNT=$(echo "$OUTDATED_FORMULAS" | wc -l | tr -d ' ')
        log "Outdated formulas ($FORMULA_COUNT):"
        echo "$OUTDATED_FORMULAS" | while read -r pkg; do
            log "  - $pkg"
        done
    else
        log "All formulas are up to date"
    fi

    # Get outdated casks
    OUTDATED_CASKS=$("$BREW" outdated --cask --greedy 2>/dev/null || true)
    if [[ -n "$OUTDATED_CASKS" ]]; then
        CASK_COUNT=$(echo "$OUTDATED_CASKS" | wc -l | tr -d ' ')
        log "Outdated casks ($CASK_COUNT):"
        echo "$OUTDATED_CASKS" | while read -r pkg; do
            log "  - $pkg"
        done
    else
        log "All casks are up to date"
    fi
else
    log "Homebrew not found, skipping brew check"
fi

# Check npm global packages (if npm exists)
if command -v npm &>/dev/null; then
    log "Checking npm global packages..."
    NPM_OUTDATED=$(npm outdated -g --depth=0 2>/dev/null || true)
    if [[ -n "$NPM_OUTDATED" ]]; then
        log "Outdated npm packages:"
        echo "$NPM_OUTDATED" >> "$LOG_FILE"
    else
        log "All npm packages are up to date"
    fi
fi

# Summary
TOTAL_OUTDATED=0
[[ -n "$OUTDATED_FORMULAS" ]] && TOTAL_OUTDATED=$((TOTAL_OUTDATED + $(echo "$OUTDATED_FORMULAS" | wc -l)))
[[ -n "$OUTDATED_CASKS" ]] && TOTAL_OUTDATED=$((TOTAL_OUTDATED + $(echo "$OUTDATED_CASKS" | wc -l)))

if [[ $TOTAL_OUTDATED -gt 0 ]]; then
    log "Total outdated packages: $TOTAL_OUTDATED"
    log "Run 'brew upgrade' to update, or 'dotfiles install' to sync with Brewfile"
fi

log "=== Outdated check finished ==="
