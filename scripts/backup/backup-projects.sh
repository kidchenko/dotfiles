#!/bin/bash
#
# backup-projects.sh - Backup project folders to local and remote storage
#
# Usage:
#   backup-projects.sh [command] [options]
#
# Commands:
#   backup      Create a new backup (default)
#   restore     Restore from a backup
#   list        List available backups
#   setup-cron  Setup scheduled backups
#   help        Show this help message
#
# Options:
#   --dry-run   Show what would be done without doing it
#   --verbose   Show detailed output
#   --local     Only backup locally (skip remote upload)
#   --config    Path to config file (default: ~/.config/dotfiles/config.yaml)
#

# Pipestatus
set -o pipefail

# --- Configuration ---
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/config.yaml"
LOG_DIR="${XDG_DATA_HOME:-$HOME/.local}/log"
LOG_FILE="$LOG_DIR/backup.log"

# Default values (overridden by config file)
BACKUP_FOLDERS=()
EXCLUDE_PATTERNS=()
BACKUP_BASE_DIR="$HOME/Backups"
BACKUP_TEMP_DIR="$BACKUP_BASE_DIR/tmp_project_backups"
LOCAL_RETENTION_DAYS=7
LOG_RETENTION_DAYS=30
RCLONE_REMOTE_NAME="GoogleDrive"
RCLONE_REMOTE_PATH="DotfilesBackups/"
REMOTE_ENABLED=true
LOGGING_ENABLED=true
CRON_SCHEDULE="0 2 * * 0"

# Runtime options
DRY_RUN=false
VERBOSE=false
UPLOAD=false
COMMAND="backup"

# Colors
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' BOLD='' NC=''
fi

# --- Helper Functions ---
say() { echo -e "${GREEN}[backup]${NC} $1"; log "INFO" "$1"; }
warn() { echo -e "${YELLOW}[backup]${NC} $1"; log "WARN" "$1"; }
error() { echo -e "${RED}[backup]${NC} $1" >&2; log "ERROR" "$1"; }
debug() { [[ "$VERBOSE" == true ]] && echo -e "${BLUE}[backup]${NC} $1"; log "DEBUG" "$1"; }

log() {
    [[ "$LOGGING_ENABLED" != true ]] && return
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    # Only log if directory exists (avoid errors during dry-run before dirs are created)
    if [[ -d "$(dirname "$LOG_FILE")" ]]; then
        echo "[$timestamp] [$level] $message" >> "$LOG_FILE" 2>/dev/null || true
    fi
}

show_help() {
    echo -e "${BOLD}backup-projects${NC} - Backup project folders"
    echo ""
    echo -e "${BOLD}Usage:${NC}"
    echo "  backup-projects.sh [command] [options]"
    echo ""
    echo -e "${BOLD}Commands:${NC}"
    echo "  backup       Create a new backup (default)"
    echo "  restore      Restore from a backup"
    echo "  list         List available backups (local and remote)"
    echo "  setup-cron   Setup scheduled backups"
    echo "  help         Show this help message"
    echo ""
    echo -e "${BOLD}Options:${NC}"
    echo "  --dry-run    Show what would be done without doing it"
    echo "  --verbose    Show detailed output"
    echo "  --upload     Upload to remote storage (Google Drive via rclone)"
    echo "  --config     Path to config file"
    echo ""
    echo -e "${BOLD}Examples:${NC}"
    echo "  backup-projects.sh                  # Create local backup"
    echo "  backup-projects.sh --upload         # Create backup and upload to Google Drive"
    echo "  backup-projects.sh --dry-run        # Preview backup"
    echo "  backup-projects.sh restore          # Restore from backup"
    echo "  backup-projects.sh list             # List backups"
    echo "  backup-projects.sh setup-cron       # Setup weekly backups"
    echo ""
    echo -e "${BOLD}Config file:${NC} $CONFIG_FILE"
    echo ""
}

# --- Config Loading ---
load_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        warn "Config file not found: $CONFIG_FILE"
        warn "Using default configuration"
        # Set default folders if no config
        BACKUP_FOLDERS=(
            "$HOME/kidchenko"
            "$HOME/lambda3"
            "$HOME/jetabroad"
            "$HOME/thoughtworks"
            "$HOME/sevenpeaks"
            "$HOME/isho"
        )
        return
    fi

    if ! command -v yq &>/dev/null; then
        warn "yq not installed, using default configuration"
        warn "Install yq: brew install yq"
        return
    fi

    debug "Loading config from $CONFIG_FILE"

    # Load folders (yq v4 syntax)
    local folders
    folders=$(yq -r '.backup.folders[]' "$CONFIG_FILE" 2>/dev/null)
    if [[ -n "$folders" ]]; then
        BACKUP_FOLDERS=()
        while IFS= read -r folder; do
            [[ -z "$folder" ]] && continue
            # Expand ~ and make absolute path
            if [[ "$folder" == /* ]]; then
                BACKUP_FOLDERS+=("$folder")
            else
                BACKUP_FOLDERS+=("$HOME/$folder")
            fi
        done <<< "$folders"
    fi

    # Load exclude patterns
    local excludes
    excludes=$(yq -r '.backup.exclude[]' "$CONFIG_FILE" 2>/dev/null)
    if [[ -n "$excludes" ]]; then
        EXCLUDE_PATTERNS=()
        while IFS= read -r pattern; do
            [[ -z "$pattern" ]] && continue
            EXCLUDE_PATTERNS+=("$pattern")
        done <<< "$excludes"
    fi

    # Load other settings (yq v4: use // "default" or just check if null)
    local val
    val=$(yq -r '.backup.local.base_dir // ""' "$CONFIG_FILE" 2>/dev/null)
    [[ -n "$val" ]] && BACKUP_BASE_DIR="${val/#\~/$HOME}"

    val=$(yq -r '.backup.local.retention_days // ""' "$CONFIG_FILE" 2>/dev/null)
    [[ -n "$val" && "$val" != "null" ]] && LOCAL_RETENTION_DAYS="$val"

    val=$(yq -r '.backup.remote.enabled // ""' "$CONFIG_FILE" 2>/dev/null)
    [[ "$val" == "false" ]] && REMOTE_ENABLED=false

    val=$(yq -r '.backup.remote.rclone_remote // ""' "$CONFIG_FILE" 2>/dev/null)
    [[ -n "$val" && "$val" != "null" ]] && RCLONE_REMOTE_NAME="$val"

    val=$(yq -r '.backup.remote.rclone_path // ""' "$CONFIG_FILE" 2>/dev/null)
    [[ -n "$val" && "$val" != "null" ]] && RCLONE_REMOTE_PATH="$val"

    val=$(yq -r '.backup.logging.enabled // ""' "$CONFIG_FILE" 2>/dev/null)
    [[ "$val" == "false" ]] && LOGGING_ENABLED=false

    val=$(yq -r '.backup.logging.dir // ""' "$CONFIG_FILE" 2>/dev/null)
    [[ -n "$val" && "$val" != "null" ]] && LOG_DIR="${val/#\~/$HOME}"

    val=$(yq -r '.backup.logging.retention_days // ""' "$CONFIG_FILE" 2>/dev/null)
    [[ -n "$val" && "$val" != "null" ]] && LOG_RETENTION_DAYS="$val"

    val=$(yq -r '.backup.schedule.cron // ""' "$CONFIG_FILE" 2>/dev/null)
    [[ -n "$val" && "$val" != "null" ]] && CRON_SCHEDULE="$val"

    # Update temp dir based on base dir
    BACKUP_TEMP_DIR="$BACKUP_BASE_DIR/tmp_project_backups"
    LOG_FILE="$LOG_DIR/backup.log"

    debug "Loaded ${#BACKUP_FOLDERS[@]} folders, ${#EXCLUDE_PATTERNS[@]} exclude patterns"
}

# --- Parse Arguments ---
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            backup|restore|list|setup-cron|help)
                COMMAND="$1"
                ;;
            --dry-run)
                DRY_RUN=true
                ;;
            --verbose|-v)
                VERBOSE=true
                ;;
            --upload)
                UPLOAD=true
                ;;
            --config)
                shift
                CONFIG_FILE="$1"
                ;;
            --config=*)
                CONFIG_FILE="${1#*=}"
                ;;
            *)
                warn "Unknown option: $1"
                ;;
        esac
        shift
    done
}

# --- Build Exclude Arguments for Zip ---
build_exclude_args() {
    local args=()
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        args+=("-x" "*/${pattern}/*" "-x" "*/${pattern}")
    done
    echo "${args[@]}"
}

# --- Backup Command ---
cmd_backup() {
    local script_start_time
    script_start_time=$(date +%s)

    say "Starting backup at $(date '+%Y-%m-%d %H:%M:%S')"

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${YELLOW}--- DRY RUN MODE ---${NC}"
    fi

    # Setup directories
    if [[ "$DRY_RUN" != true ]]; then
        mkdir -p "$BACKUP_TEMP_DIR"
        mkdir -p "$LOG_DIR"
    else
        debug "Would create: $BACKUP_TEMP_DIR"
        debug "Would create: $LOG_DIR"
    fi

    # Find existing folders
    local existing_folders=()
    say "Checking folders to backup..."
    for folder in "${BACKUP_FOLDERS[@]}"; do
        if [[ -d "$folder" ]]; then
            echo -e "  ${GREEN}✓${NC} $folder"
            existing_folders+=("$folder")
        else
            echo -e "  ${YELLOW}!${NC} $folder (not found, skipping)"
        fi
    done

    if [[ ${#existing_folders[@]} -eq 0 ]]; then
        warn "No folders found to backup"
        return 1
    fi

    # Create archive
    local timestamp
    timestamp=$(date +"%Y%m%d-%H%M%S")
    local archive_name="project-backup-${timestamp}.zip"
    local archive_path="$BACKUP_TEMP_DIR/$archive_name"

    # Prepare relative paths
    local relative_paths=()
    for folder in "${existing_folders[@]}"; do
        relative_paths+=("${folder#$HOME/}")
    done

    say "Creating archive: $archive_name"
    if [[ ${#EXCLUDE_PATTERNS[@]} -gt 0 ]]; then
        debug "Excluding: ${EXCLUDE_PATTERNS[*]}"
    fi

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${BLUE}Would archive:${NC}"
        for path in "${relative_paths[@]}"; do
            echo "  - $path"
        done
        if [[ ${#EXCLUDE_PATTERNS[@]} -gt 0 ]]; then
            echo -e "${BLUE}Excluding patterns:${NC}"
            for pattern in "${EXCLUDE_PATTERNS[@]}"; do
                echo "  - $pattern"
            done
        fi
    else
        local exclude_args
        exclude_args=$(build_exclude_args)

        (
            cd "$HOME" || exit 1
            if [[ "$VERBOSE" == true ]]; then
                # shellcheck disable=SC2086
                zip -r "$archive_path" "${relative_paths[@]}" $exclude_args
            else
                # shellcheck disable=SC2086
                zip -r -q "$archive_path" "${relative_paths[@]}" $exclude_args
            fi
        )

        if [[ ! -f "$archive_path" ]]; then
            error "Failed to create archive"
            return 1
        fi

        local archive_size
        archive_size=$(du -h "$archive_path" | cut -f1)
        say "Archive created: $archive_size"
    fi

    # Upload to remote (only if --upload flag is provided)
    if [[ "$UPLOAD" == true ]]; then
        if ! command -v rclone &>/dev/null; then
            warn "rclone not installed. Install with: brew install rclone"
            warn "Then configure: rclone config"
        else
            say "Uploading to ${RCLONE_REMOTE_NAME}:${RCLONE_REMOTE_PATH}..."
            if [[ "$DRY_RUN" == true ]]; then
                debug "Would upload $archive_name to ${RCLONE_REMOTE_NAME}:${RCLONE_REMOTE_PATH}"
            else
                if rclone copy "$archive_path" "${RCLONE_REMOTE_NAME}:${RCLONE_REMOTE_PATH}" --progress; then
                    say "Upload complete"
                else
                    error "Upload failed"
                fi
            fi
        fi
    fi

    # Cleanup old backups
    say "Cleaning up backups older than $LOCAL_RETENTION_DAYS days..."
    if [[ "$DRY_RUN" == true ]]; then
        debug "Would delete old backups from $BACKUP_TEMP_DIR"
    else
        find "$BACKUP_TEMP_DIR" -name "*.zip" -mtime +"$LOCAL_RETENTION_DAYS" -print -delete 2>/dev/null || true
    fi

    # Cleanup old logs
    if [[ "$LOGGING_ENABLED" == true ]]; then
        find "$LOG_DIR" -name "backup*.log" -mtime +"$LOG_RETENTION_DAYS" -delete 2>/dev/null || true
    fi

    # Summary
    local script_end_time
    script_end_time=$(date +%s)
    local total_time=$((script_end_time - script_start_time))

    echo ""
    say "Backup complete in ${total_time}s"

    # macOS notification
    if command -v osascript &>/dev/null && [[ "$DRY_RUN" != true ]]; then
        local title="Backup Complete"
        local message="Archived ${#existing_folders[@]} folders in ${total_time}s"
        osascript -e "display notification \"$message\" with title \"$title\"" 2>/dev/null || true
    fi
}

# --- List Command ---
cmd_list() {
    say "Available backups"
    echo ""

    # Local backups
    echo -e "${BOLD}Local backups:${NC} $BACKUP_TEMP_DIR"
    if [[ -d "$BACKUP_TEMP_DIR" ]]; then
        local count=0
        while IFS= read -r file; do
            [[ -z "$file" ]] && continue
            local size
            size=$(du -h "$file" | cut -f1)
            local date
            date=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$file" 2>/dev/null || stat --format="%y" "$file" 2>/dev/null | cut -d'.' -f1)
            echo "  $(basename "$file") ($size) - $date"
            ((count++))
        done < <(find "$BACKUP_TEMP_DIR" -name "*.zip" -type f 2>/dev/null | sort -r)

        if [[ $count -eq 0 ]]; then
            echo "  (no backups found)"
        fi
    else
        echo "  (directory does not exist)"
    fi

    echo ""

    # Remote backups
    if [[ "$REMOTE_ENABLED" == true ]] && command -v rclone &>/dev/null; then
        echo -e "${BOLD}Remote backups:${NC} ${RCLONE_REMOTE_NAME}:${RCLONE_REMOTE_PATH}"
        if rclone lsf "${RCLONE_REMOTE_NAME}:${RCLONE_REMOTE_PATH}" --format "sp" 2>/dev/null | head -20; then
            :
        else
            echo "  (could not list remote backups)"
        fi
    fi
}

# --- Restore Command ---
cmd_restore() {
    say "Restore from backup"
    echo ""

    # List available backups
    local backups=()
    local i=1

    echo -e "${BOLD}Available local backups:${NC}"
    echo -e "  Location: $BACKUP_TEMP_DIR"
    echo ""
    if [[ -d "$BACKUP_TEMP_DIR" ]]; then
        while IFS= read -r file; do
            [[ -z "$file" ]] && continue
            local size
            size=$(du -h "$file" | cut -f1)
            local date
            date=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$file" 2>/dev/null || stat --format="%y" "$file" 2>/dev/null | cut -d'.' -f1)
            echo "  $i) $(basename "$file") ($size) - $date"
            backups+=("$file")
            ((i++))
        done < <(find "$BACKUP_TEMP_DIR" -maxdepth 1 -name "project-backup-*.zip" -type f 2>/dev/null | sort -r)
    fi

    if [[ ${#backups[@]} -eq 0 ]]; then
        echo "  (no local backups found)"
        echo ""

        # Check remote
        if [[ "$REMOTE_ENABLED" == true ]] && command -v rclone &>/dev/null; then
            echo -e "${BOLD}Remote backups available:${NC}"
            rclone lsf "${RCLONE_REMOTE_NAME}:${RCLONE_REMOTE_PATH}" 2>/dev/null | head -10
            echo ""
            echo "To restore from remote, first download with:"
            echo "  rclone copy ${RCLONE_REMOTE_NAME}:${RCLONE_REMOTE_PATH}<filename> $BACKUP_TEMP_DIR"
        fi
        return 1
    fi

    echo ""
    echo -n "Select backup to restore (1-${#backups[@]}) or 'q' to quit: "
    read -r selection

    if [[ "$selection" == "q" || "$selection" == "Q" ]]; then
        say "Restore cancelled"
        return 0
    fi

    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [[ "$selection" -lt 1 ]] || [[ "$selection" -gt ${#backups[@]} ]]; then
        error "Invalid selection"
        return 1
    fi

    local selected_backup="${backups[$((selection-1))]}"
    local backup_name
    backup_name=$(basename "$selected_backup")

    echo ""
    say "Selected: $backup_name"
    echo ""

    # Show contents
    echo -e "${BOLD}Archive contents:${NC}"
    unzip -l "$selected_backup" | head -30
    echo "..."
    echo ""

    # Confirm restore location
    local restore_dir="$HOME"
    echo -n "Restore to [$restore_dir]: "
    read -r custom_dir
    [[ -n "$custom_dir" ]] && restore_dir="${custom_dir/#\~/$HOME}"

    echo ""
    warn "This will extract files to: $restore_dir"
    warn "Existing files may be overwritten!"
    echo -n "Continue? [y/N]: "
    read -r confirm

    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        say "Restore cancelled"
        return 0
    fi

    # Perform restore
    say "Restoring..."
    if [[ "$DRY_RUN" == true ]]; then
        debug "Would extract $selected_backup to $restore_dir"
    else
        # Create restore directory if it doesn't exist
        if [[ ! -d "$restore_dir" ]]; then
            say "Creating directory: $restore_dir"
            mkdir -p "$restore_dir"
        fi

        if unzip -o "$selected_backup" -d "$restore_dir"; then
            say "Restore complete!"
        else
            error "Restore failed"
            return 1
        fi
    fi
}

# --- Setup Cron Command ---
cmd_setup_cron() {
    say "Setting up scheduled backups"

    local script_path
    script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

    # Also check chezmoi location
    local chezmoi_script="${XDG_DATA_HOME:-$HOME/.local/share}/chezmoi/scripts/backup/backup-projects.sh"
    if [[ -f "$chezmoi_script" ]]; then
        script_path="$chezmoi_script"
    fi

    local cron_entry="$CRON_SCHEDULE $script_path backup >> $LOG_DIR/backup-cron.log 2>&1"

    echo ""
    echo -e "${BOLD}Cron schedule:${NC} $CRON_SCHEDULE"
    echo -e "${BOLD}Script:${NC} $script_path"
    echo -e "${BOLD}Log:${NC} $LOG_DIR/backup-cron.log"
    echo ""
    echo "Cron entry to add:"
    echo "  $cron_entry"
    echo ""

    if [[ "$DRY_RUN" == true ]]; then
        debug "Would add cron entry"
        return 0
    fi

    # Check if already exists
    if crontab -l 2>/dev/null | grep -q "backup-projects.sh"; then
        warn "Backup cron job already exists"
        echo -n "Replace existing entry? [y/N]: "
        read -r confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            return 0
        fi
        # Remove existing
        crontab -l 2>/dev/null | grep -v "backup-projects.sh" | crontab -
    fi

    # Add new entry
    (crontab -l 2>/dev/null; echo "$cron_entry") | crontab -

    if crontab -l 2>/dev/null | grep -q "backup-projects.sh"; then
        say "Cron job added successfully"
    else
        error "Failed to add cron job"
        return 1
    fi
}

# --- Main ---
main() {
    parse_args "$@"

    if [[ "$COMMAND" == "help" ]]; then
        show_help
        return 0
    fi

    load_config

    case "$COMMAND" in
        backup)
            cmd_backup
            ;;
        restore)
            cmd_restore
            ;;
        list)
            cmd_list
            ;;
        setup-cron)
            cmd_setup_cron
            ;;
        *)
            error "Unknown command: $COMMAND"
            show_help
            return 1
            ;;
    esac
}

main "$@"
