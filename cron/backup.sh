#!/usr/bin/env bash
#
# backup.sh - Weekly backup with 2-backup retention
#
# Runs backup-projects.sh and keeps only 2 backups (current + previous week)
# Logs output to ~/.local/log/backup-cron.log

set -e

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_SCRIPT="$DOTFILES_DIR/scripts/backup/backup-projects.sh"
LOG_DIR="${HOME}/.local/log"
LOG_FILE="$LOG_DIR/backup-cron.log"
BACKUP_DIR="${HOME}/Backups/tmp_project_backups"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log "=== Starting weekly backup ==="

# Run backup
if "$BACKUP_SCRIPT" backup >> "$LOG_FILE" 2>&1; then
    log "Backup completed successfully"
else
    log "ERROR: Backup failed"
    exit 1
fi

# Keep only 2 most recent backups
log "Cleaning up old backups (keeping 2 most recent)..."
if [[ -d "$BACKUP_DIR" ]]; then
    # List all backup files sorted by date (newest first), skip first 2, delete the rest
    # Using ls -t for macOS compatibility (instead of GNU find -printf)
    ls -t "$BACKUP_DIR"/project-backup-*.zip 2>/dev/null | \
        tail -n +3 | \
        while read -r file; do
            log "Removing old backup: $file"
            rm -f "$file"
        done
fi

log "=== Finished ==="
