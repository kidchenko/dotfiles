#!/usr/bin/env bash
#
# setup-cron.sh - Install cron job for weekly brew bundle
#
# Schedules update.sh to run every Monday at 9am

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPDATE_SCRIPT="$SCRIPT_DIR/update.sh"

# Cron job: Every Monday at 9am
CRON_SCHEDULE="0 9 * * 1"
CRON_JOB="$CRON_SCHEDULE $UPDATE_SCRIPT"

# Check if job already exists
if crontab -l 2>/dev/null | grep -qF "$UPDATE_SCRIPT"; then
    echo "[cron] Job already exists. Updating..."
    # Remove old job and add new one
    (crontab -l 2>/dev/null | grep -vF "$UPDATE_SCRIPT"; echo "$CRON_JOB") | crontab -
    echo "[cron] Job updated: $CRON_JOB"
else
    # Add new cron job
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "[cron] Job added: $CRON_JOB"
fi

echo "[cron] Current crontab:"
crontab -l
