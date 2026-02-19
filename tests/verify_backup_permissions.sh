#!/bin/bash
set -e

# Setup test environment
# Use mktemp directory
TEST_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'test_backup')
BACKUP_DIR="$TEST_DIR/backups"
SOURCE_DIR="$TEST_DIR/source"
CONFIG_FILE="$TEST_DIR/config.yaml"

mkdir -p "$SOURCE_DIR"
echo "secret" > "$SOURCE_DIR/secret.txt"

# Create config file
cat <<EOF > "$CONFIG_FILE"
backup:
  folders:
    - "$SOURCE_DIR"
  local:
    base_dir: "$BACKUP_DIR"
  remote:
    enabled: false
  logging:
    enabled: false
EOF

# Determine repo root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_SCRIPT="$REPO_ROOT/tools/backup-projects.sh"

echo "Running backup script: $BACKUP_SCRIPT"
# Run the backup command
# We ignore output to reduce noise, but capture errors if needed
bash "$BACKUP_SCRIPT" --config "$CONFIG_FILE" backup > "$TEST_DIR/backup.log" 2>&1 || {
    echo "Backup script failed. Log:"
    cat "$TEST_DIR/backup.log"
    rm -rf "$TEST_DIR"
    exit 1
}

# Check permissions
BACKUP_ARCHIVE=$(find "$BACKUP_DIR" -name "*.zip" | head -n 1)

if [[ ! -f "$BACKUP_ARCHIVE" ]]; then
    echo "Backup failed: No archive created"
    rm -rf "$TEST_DIR"
    exit 1
fi

# Get permissions (Linux stat)
if stat --version 2>/dev/null | grep -q "GNU"; then
    # GNU stat
    PERMS=$(stat -c "%a" "$BACKUP_ARCHIVE")
    DIR_PERMS=$(stat -c "%a" "$BACKUP_DIR")
elif stat --version 2>/dev/null; then
     # Fallback for other stats that might support --version but not be GNU (unlikely)
     PERMS=$(stat -c "%a" "$BACKUP_ARCHIVE")
     DIR_PERMS=$(stat -c "%a" "$BACKUP_DIR")
else
    # BSD stat (macOS) - stat --version usually fails on BSD stat
    # Try BSD syntax
    if stat -f "%Lp" "$BACKUP_ARCHIVE" >/dev/null 2>&1; then
        PERMS=$(stat -f "%Lp" "$BACKUP_ARCHIVE")
        DIR_PERMS=$(stat -f "%Lp" "$BACKUP_DIR")
    else
        # Fallback to GNU syntax if --version check failed but it is GNU
        PERMS=$(stat -c "%a" "$BACKUP_ARCHIVE")
        DIR_PERMS=$(stat -c "%a" "$BACKUP_DIR")
    fi
fi

echo "Backup Archive Permissions: $PERMS"
echo "Backup Directory Permissions: $DIR_PERMS"

FAILED=0

# Check archive permissions (should be 600 or 400)
if [[ "$PERMS" != "600" && "$PERMS" != "400" ]]; then
    echo "FAIL: Insecure archive permissions ($PERMS). Expected 600 or 400."
    FAILED=1
else
    echo "PASS: Archive permissions are secure."
fi

# Check directory permissions (should be 700)
if [[ "$DIR_PERMS" != "700" ]]; then
    echo "FAIL: Insecure directory permissions ($DIR_PERMS). Expected 700."
    FAILED=1
else
    echo "PASS: Directory permissions are secure."
fi

rm -rf "$TEST_DIR"

if [[ $FAILED -eq 1 ]]; then
    exit 1
fi

exit 0
