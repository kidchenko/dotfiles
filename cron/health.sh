#!/usr/bin/env bash
#
# health.sh - Daily system health check
#
# Runs doctor.sh to verify system configuration is healthy.
# Logs output to ~/.local/state/dotfiles/health.log
# Exit code indicates if issues were found (for notification integration)

set -e

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
DOCTOR_SCRIPT="$DOTFILES_DIR/tools/doctor.sh"
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
LOG_FILE="$LOG_DIR/health.log"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log "=== Starting daily health check ==="

# Check if doctor script exists
if [[ ! -f "$DOCTOR_SCRIPT" ]]; then
    log "ERROR: Doctor script not found at $DOCTOR_SCRIPT"
    exit 1
fi

# Run doctor with --quick to skip slow checks (those run separately)
# Capture output and exit code
DOCTOR_OUTPUT=$("$DOCTOR_SCRIPT" --quick 2>&1) || DOCTOR_EXIT=$?
DOCTOR_EXIT=${DOCTOR_EXIT:-0}

# Log the output
echo "$DOCTOR_OUTPUT" >> "$LOG_FILE"

if [[ $DOCTOR_EXIT -eq 0 ]]; then
    log "Health check passed"
else
    log "WARNING: Health check found issues (exit code: $DOCTOR_EXIT)"

    # Count warnings and errors from output
    WARNINGS=$(echo "$DOCTOR_OUTPUT" | grep -c "⚠" || true)
    ERRORS=$(echo "$DOCTOR_OUTPUT" | grep -c "✗" || true)
    log "Found $WARNINGS warnings and $ERRORS errors"
fi

log "=== Health check finished ==="

exit $DOCTOR_EXIT
