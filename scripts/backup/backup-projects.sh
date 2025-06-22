#!/bin/bash

# backup-projects.sh
#
# Archives a list of project folders and uploads them to Google Drive.

# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
set -u
# Pipestatus: Return value of a pipeline is the value of the last command to exit with a non-zero status,
# or zero if all commands in the pipeline exit successfully.
set -o pipefail

# --- Configuration ---
# TODO: Consider moving this to a config file or command-line arguments for more flexibility
PROJECT_FOLDERS_TO_BACKUP=(
    "$HOME/lambda3"
    "$HOME/jetabroad"
    "$HOME/thoughtworks"
    "$HOME/sevenpeaks"
    "$HOME/isho"
    "$HOME/kidchenko"
    # Add more folders here as needed
)

# TODO: Implement encryption (GPG or zip password) as a future enhancement.
# This would require:
# - Additional command-line flags (e.g., --encrypt-gpg <key_id>, --encrypt-zip-password)
# - Logic to handle password input securely if needed.
# - Modifying the zip command for password protection or adding a GPG encryption step.
# - Modifying the rclone command if GPG is used before upload (e.g., uploading .gpg file).
# - Updating cleanup logic to handle encrypted files.

BACKUP_BASE_DIR="$HOME/Backups"
BACKUP_TEMP_DIR="$BACKUP_BASE_DIR/tmp_project_backups" # Store zips here before deciding on final location or upload
RCLONE_REMOTE_NAME="GoogleDrive" # IMPORTANT: User needs to have this rclone remote configured
RCLONE_REMOTE_PATH="DotfilesBackups/" # Destination path on Google Drive

DRY_RUN=false # Default to not a dry run

# --- Helper Functions ---
parse_args() {
    # Simple argument parsing for --dry-run
    for arg in "$@"; do
        case $arg in
            --dry-run)
                DRY_RUN=true
                shift # Remove --dry-run from processing
                ;;
            # Add more arguments here if needed in the future
            # Example:
            # --config-file)
            # CONFIG_FILE="$2"
            # shift 2
            # ;;
            *)
                # Silently ignore unknown options for now
                ;;
        esac
    done
}

# --- Main Function ---
main() {
    local script_start_time
    script_start_time=$(date +%s)

    parse_args "$@"

    if [ "$DRY_RUN" = true ]; then
        echo "--- DRY RUN MODE ENABLED ---"
        echo "No actual archiving, uploading, or cleanup will be performed."
        echo "----------------------------"
    fi

    echo "Project backup script started at $(date '+%Y-%m-%d %H:%M:%S')."

    # --- 1. Initialize & Setup ---
    echo "Project backup script started at $(date '+%Y-%m-%d %H:%M:%S')."
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would create backup directory: $BACKUP_TEMP_DIR (if it doesn't exist)"
    else
        mkdir -p "$BACKUP_TEMP_DIR" # Ensure backup temporary directory exists
    fi

    # --- 2. Identify Folders to Backup ---
    local existing_folders_to_archive=()
    local expanded_folder_path # Declare here for broader scope if needed, though current use is fine
    echo "Checking project folders to back up..."
    for folder_path in "${PROJECT_FOLDERS_TO_BACKUP[@]}"; do
        expanded_folder_path="${folder_path/#\~/$HOME}" # Expand tilde
        if [ -d "$expanded_folder_path" ]; then
            echo "  [FOUND] $expanded_folder_path"
            existing_folders_to_archive+=("$expanded_folder_path")
        else
            echo "  [SKIPPED] Folder not found: $expanded_folder_path"
        fi
    done

    # --- 3. Archive Creation ---
    local archive_name="" # Initialize to empty
    local archive_path="" # Initialize to empty

    if [ ${#existing_folders_to_archive[@]} -eq 0 ]; then
        echo "No project folders found to back up. Exiting process."
        # No archive created, so statistics and notification will reflect this.
    else
        echo "Preparing to archive ${#existing_folders_to_archive[@]} folder(s)..."

        local timestamp
        timestamp=$(date +"%Y%m%d-%H%M")
        archive_name="project-backup-${timestamp}.zip"
        archive_path="$BACKUP_TEMP_DIR/$archive_name"

        # Prepare relative paths for zipping to keep archive clean
        local relative_paths_to_archive=()
        for folder in "${existing_folders_to_archive[@]}"; do
            relative_paths_to_archive+=("${folder#$HOME/}")
        done

        echo "Target archive: $archive_path"
        if [ "$DRY_RUN" = true ]; then
            echo "[DRY RUN] Would create archive with the following relative paths (from \$HOME):"
            for rel_path in "${relative_paths_to_archive[@]}"; do
                echo "  - $rel_path"
            done
        else
            echo "Creating archive..."
            # Using a subshell for 'cd' to avoid changing current script directory
            (
                cd "$HOME" || { echo "Error: Failed to change directory to $HOME for zipping."; exit 1; }
                zip -r -q "$archive_path" "${relative_paths_to_archive[@]}"
            )
            if [ $? -ne 0 ]; then
                echo "Error: Failed to create archive $archive_path."
                return 1 # Indicate failure
            fi
            echo "Archive created successfully."
        fi
    fi

    # --- 4. Upload to Remote Storage (rclone) ---
    if [ -n "$archive_path" ]; then # Proceed only if an archive was supposed to be created
        if [ "$DRY_RUN" = true ]; then
            echo "[DRY RUN] Would upload $archive_name from $archive_path to $RCLONE_REMOTE_NAME:$RCLONE_REMOTE_PATH"
        else
            echo "Uploading $archive_name to $RCLONE_REMOTE_NAME:$RCLONE_REMOTE_PATH..."
            if rclone copy "$archive_path" "${RCLONE_REMOTE_NAME}:${RCLONE_REMOTE_PATH}"; then
                echo "Upload successful."
            else
                echo "Error: rclone upload failed for $archive_name."
                # Consider policy: delete local archive? For now, it's kept.
                return 1 # Indicate failure
            fi
        fi
    elif [ ${#existing_folders_to_archive[@]} -gt 0 ]; then
        # This case implies dry run with folders found, but archive_path is empty (which shouldn't happen due to logic above)
        # Or, a non-dry-run where archive creation was skipped (e.g. error before actual zip)
        echo "Skipping upload: Archive was not created or not applicable."
    fi

    # --- 5. Cleanup Old Local Backups ---
    # This runs regardless of whether a new backup was made, to maintain the temp dir.
    echo "Cleaning up old local backups (older than 7 days) in $BACKUP_TEMP_DIR..."
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would search for .zip files older than 7 days in $BACKUP_TEMP_DIR and delete them."
        echo "[DRY RUN] Command: find \"$BACKUP_TEMP_DIR\" -name \"*.zip\" -mtime +7 -print"
    else
        # Using -print before -delete to log which files are being removed.
        find "$BACKUP_TEMP_DIR" -name "*.zip" -mtime +7 -print -delete
        echo "Cleanup of old local backups complete."
    fi

    # --- 6. Statistics Reporting ---
    local archive_size="N/A"
    if [ -n "$archive_path" ] && [ "$DRY_RUN" = false ] && [ -f "$archive_path" ]; then
        archive_size=$(du -h "$archive_path" | cut -f1)
    elif [ -n "$archive_path" ] && [ "$DRY_RUN" = true ]; then
        archive_size="N/A (Dry Run)"
    elif [ ${#existing_folders_to_archive[@]} -eq 0 ]; then
        archive_size="N/A (No folders to archive)"
    fi
    echo "Archive size: $archive_size"

    local script_end_time
    script_end_time=$(date +%s)
    local total_time_seconds=$((script_end_time - script_start_time))
    echo "Total time taken: ${total_time_seconds} seconds."
    echo "Project backup script finished at $(date '+%Y-%m-%d %H:%M:%S')."

    # --- 7. macOS Notification ---
    if command -v osascript &> /dev/null; then
        local notification_title="Project Backup"
        local notification_message

        if [ "$DRY_RUN" = true ]; then
            notification_title="[DRY RUN] Project Backup Simulation"
        fi

        if [ ${#existing_folders_to_archive[@]} -eq 0 ]; then
            notification_message="No project folders found to back up. Finished in ${total_time_seconds}s."
            notification_title="${notification_title} - No Action"
        elif [ -n "${archive_name}" ]; then # archive_name is set if archiving was attempted
             notification_message="Archive '${archive_name}' processed. Size: ${archive_size}. Total time: ${total_time_seconds}s."
             notification_title="${notification_title} Complete" # Assumes success if script reaches here due to set -e
        else
            # Fallback, though ideally not reached if logic is sound
            notification_message="Backup process finished in ${total_time_seconds}s. Status unclear (review logs)."
            notification_title="${notification_title} - Check Status"
        fi

        osascript -e "display notification \"${notification_message}\" with title \"${notification_title}\""
    else
        echo "osascript command not found, skipping macOS notification."
    fi
}

# Call the main function
# Ensure all arguments are passed to main, especially for parse_args
main "$@"
