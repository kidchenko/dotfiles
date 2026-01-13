#!/usr/bin/env bash
#
# git-maintenance.sh - Weekly git repository maintenance
#
# Runs git gc and maintenance on important repositories to keep them fast.
# Logs output to ~/.local/state/dotfiles/git-maintenance.log

set -e

# Paths
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
LOG_FILE="$LOG_DIR/git-maintenance.log"
CHEZMOI_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/chezmoi"

# Project directories to maintain (same as backup config)
PROJECT_DIRS=(
    "$HOME/kidchenko"
    "$HOME/lambda3"
    "$HOME/jetabroad"
)

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Run git maintenance on a single repo
maintain_repo() {
    local repo="$1"
    local name
    name=$(basename "$repo")

    if [[ ! -d "$repo/.git" ]]; then
        return
    fi

    log "Maintaining: $name"

    # Run git gc (garbage collection)
    if git -C "$repo" gc --quiet 2>/dev/null; then
        log "  gc: done"
    else
        log "  gc: failed"
    fi

    # Prune old reflog entries (older than 30 days)
    if git -C "$repo" reflog expire --expire=30.days --all 2>/dev/null; then
        log "  reflog prune: done"
    fi
}

# Find and maintain all git repos in a directory (1 level deep)
maintain_repos_in_dir() {
    local dir="$1"

    if [[ ! -d "$dir" ]]; then
        log "Directory not found: $dir"
        return
    fi

    log "Scanning: $dir"

    # Find git repos (only 1 level deep to avoid nested repos)
    for repo in "$dir"/*/; do
        if [[ -d "${repo}.git" ]]; then
            maintain_repo "${repo%/}"
        fi
    done
}

log "=== Starting weekly git maintenance ==="

# Maintain chezmoi repo first
if [[ -d "$CHEZMOI_DIR/.git" ]]; then
    maintain_repo "$CHEZMOI_DIR"
fi

# Maintain project directories
for dir in "${PROJECT_DIRS[@]}"; do
    maintain_repos_in_dir "$dir"
done

log "=== Git maintenance finished ==="
