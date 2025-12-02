#!/usr/bin/env bash
#
# setup-cron.sh - Install cron jobs for dotfiles
#
# Jobs:
#   - update.sh: Weekly brew bundle (Monday 9am)
#   - backup.sh: Weekly backup (Sunday 2am)

set -e

# Always use chezmoi path for cron jobs (not the git repo path)
CRON_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/chezmoi/cron"

# Define cron jobs: "script|schedule|description"
CRON_JOBS=(
    "update.sh|0 9 * * 1|Weekly brew bundle (Monday 9am)"
    "backup.sh|0 2 * * 0|Weekly backup (Sunday 2am)"
)

echo "[cron] Setting up dotfiles cron jobs..."
echo "[cron] Using path: $CRON_DIR"
echo ""

# First, remove any old dotfiles cron entries (from any path)
echo "[cron] Cleaning up old entries..."
crontab -l 2>/dev/null | grep -vE "cron/(update|backup)\.sh" | crontab - 2>/dev/null || true

for entry in "${CRON_JOBS[@]}"; do
    script="${entry%%|*}"
    remainder="${entry#*|}"
    schedule="${remainder%%|*}"
    description="${remainder#*|}"

    script_path="$CRON_DIR/$script"
    cron_job="$schedule $script_path"

    if [[ ! -f "$script_path" ]]; then
        echo "[cron] ⚠ Script not found: $script_path"
        continue
    fi

    echo "[cron] + $description"
    (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
done

echo ""
echo "[cron] Current crontab:"
crontab -l
