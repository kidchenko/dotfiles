#!/bin/bash

# Setup test environment
PROJECT_DIR="$HOME/kidchenko"
BACKUP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles/backups"
BACKUP_DIR="${BACKUP_DIR/#\~/$HOME}" # Expand ~ just in case

# Create dummy project
mkdir -p "$PROJECT_DIR"
echo "secret content" > "$PROJECT_DIR/secret.txt"

# Ensure cleanup
trap 'rm -rf "$PROJECT_DIR"' EXIT

# Run backup script
# It reads default folders which includes ~/kidchenko
echo "Running backup script..."
# Using --verbose to see output, but suppressing standard output unless needed
if ! bash tools/backup-projects.sh backup --verbose > /tmp/backup_output.log 2>&1; then
    echo "Backup failed. Output:"
    cat /tmp/backup_output.log
    exit 1
fi

# Find the latest backup
LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/project-backup-*.zip 2>/dev/null | head -n1)

if [[ -z "$LATEST_BACKUP" ]]; then
  echo "Error: No backup file created in $BACKUP_DIR"
  cat /tmp/backup_output.log
  exit 1
fi

echo "Backup created: $LATEST_BACKUP"

# Check permissions
if [[ "$OSTYPE" == "darwin"* ]]; then
  PERMS=$(stat -f %Lp "$LATEST_BACKUP")
else
  PERMS=$(stat -c %a "$LATEST_BACKUP")
fi

echo "Permissions: $PERMS"

# Cleanup backup file
rm -f "$LATEST_BACKUP"

# We expect 600 (rw-------)
if [[ "$PERMS" != "600" ]]; then
  echo "FAILURE: Permissions are too open ($PERMS). Expected 600."
  exit 1
else
  echo "SUCCESS: Permissions are correct (600)."
  exit 0
fi
