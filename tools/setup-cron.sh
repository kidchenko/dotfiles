#!/usr/bin/env bash
#
# setup-cron.sh - Install cron jobs for dotfiles
#
# Reads job definitions from ~/.config/dotfiles/config.yaml
#
# Usage:
#   setup-cron.sh [--dry-run]

set -e

# Configuration
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/config.yaml"
CRON_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/chezmoi/cron"

# Options
DRY_RUN=false

# Colors
if [[ -t 1 ]]; then
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    NC='\033[0m'
else
    GREEN='' YELLOW='' NC=''
fi

say() { echo -e "${GREEN}[cron]${NC} $1"; }
warn() { echo -e "${YELLOW}[cron]${NC} $1"; }

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true ;;
        *) ;;
    esac
    shift
done

# Check dependencies
if ! command -v yq &>/dev/null; then
    warn "yq not installed. Install with: brew install yq"
    exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
    warn "Config file not found: $CONFIG_FILE"
    warn "Run 'chezmoi apply' to create it"
    exit 1
fi

say "Setting up cron jobs from config.yaml..."
say "Scripts directory: $CRON_DIR"
echo ""

# Get all cron scripts to clean up old entries
scripts=$(yq -r '.cron.jobs[].script' "$CONFIG_FILE" 2>/dev/null | tr '\n' '|' | sed 's/|$//')

if [[ -z "$scripts" || "$scripts" == "null" ]]; then
    warn "No cron jobs defined in config.yaml"
    exit 0
fi

# Clean up old entries
say "Cleaning up old entries..."
if [[ "$DRY_RUN" != true ]]; then
    crontab -l 2>/dev/null | grep -vE "cron/($scripts)" | crontab - 2>/dev/null || true
fi

# Read and install each job
job_count=$(yq -r '.cron.jobs | length' "$CONFIG_FILE")

for ((i=0; i<job_count; i++)); do
    script=$(yq -r ".cron.jobs[$i].script" "$CONFIG_FILE")
    schedule=$(yq -r ".cron.jobs[$i].schedule" "$CONFIG_FILE")
    description=$(yq -r ".cron.jobs[$i].description" "$CONFIG_FILE")

    script_path="$CRON_DIR/$script"
    cron_job="$schedule $script_path"

    if [[ ! -f "$script_path" ]]; then
        warn "⚠ Script not found: $script_path"
        continue
    fi

    if [[ "$DRY_RUN" == true ]]; then
        echo "  Would add: $description"
        echo "    $cron_job"
    else
        say "+ $description"
        (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
    fi
done

echo ""
if [[ "$DRY_RUN" == true ]]; then
    say "Dry run complete. No changes made."
else
    say "Cron jobs installed successfully"
    echo ""
    say "Current crontab:"
    crontab -l
fi
