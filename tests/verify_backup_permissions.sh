#!/bin/bash
set -e

# Setup test paths
TEST_DIR="$(mktemp -d)"
TEST_SOURCE="$TEST_DIR/source"
TEST_BACKUP_DIR="$TEST_DIR/backups"
TEST_CONFIG="$TEST_DIR/config.yaml"
SCRIPT_PATH="$(pwd)/tools/backup-projects.sh"

# Cleanup on exit
trap 'rm -rf "$TEST_DIR"' EXIT

# Create source directory with a file
mkdir -p "$TEST_SOURCE"
echo "sensitive data" > "$TEST_SOURCE/secret.txt"

# Create config file
cat > "$TEST_CONFIG" <<EOF
backup:
  folders:
    - $TEST_SOURCE
  local:
    base_dir: $TEST_BACKUP_DIR
    retention_days: 1
  remote:
    enabled: false
  logging:
    enabled: false
EOF

# Make sure script is executable
chmod +x "$SCRIPT_PATH"

# Run backup script
"$SCRIPT_PATH" backup --config "$TEST_CONFIG" >/dev/null

# Check backup file permissions
BACKUP_FILE=$(find "$TEST_BACKUP_DIR" -name "*.zip" | head -n 1)

if [[ -z "$BACKUP_FILE" ]]; then
    echo "Backup file not found!"
    exit 1
fi

if [[ "$(uname -s)" == "Darwin" ]]; then
    PERMS=$(stat -f "%Lp" "$BACKUP_FILE")
    DIR_PERMS=$(stat -f "%Lp" "$TEST_BACKUP_DIR")
else
    PERMS=$(stat -c "%a" "$BACKUP_FILE")
    DIR_PERMS=$(stat -c "%a" "$TEST_BACKUP_DIR")
fi
echo "Backup file permissions: $PERMS"
echo "Backup directory permissions: $DIR_PERMS"

FAILED=0

# Verify if permissions are secure (600 for file, 700 for directory)
if [[ "$PERMS" != "600" ]]; then
    echo "FAIL: Backup file permissions are not 600"
    FAILED=1
else
    echo "PASS: Backup file permissions are 600"
fi

if [[ "$DIR_PERMS" != "700" ]]; then
    echo "FAIL: Backup directory permissions are not 700"
    FAILED=1
else
    echo "PASS: Backup directory permissions are 700"
fi

exit $FAILED
