#!/bin/bash
# Test for secure file creation logic
set -e

TEST_FILE="tests/ssh_key_test"

# Function to check permissions
check_permissions() {
    local file="$1"
    local expected="$2"
    local perms
    if [[ "$(uname -s)" == "Darwin" ]]; then
        perms=$(stat -f "%Lp" "$file")
    else
        perms=$(stat -c "%a" "$file")
    fi

    if [[ "$perms" != "$expected" ]]; then
        echo "FAIL: Permissions for $file are $perms, expected $expected"
        return 1
    else
        echo "PASS: Permissions for $file are $perms"
        return 0
    fi
}

echo "=== Test 1: Insecure Creation (Baseline) ==="
rm -f "$TEST_FILE"
# Standard creation (vulnerable pattern)
echo "secret" > "$TEST_FILE"
# Check if permissions are 644 (or 664 depending on umask)
# Assuming default umask 022 -> 644
# We check if it is NOT 600
perms=$(stat -c "%a" "$TEST_FILE" 2>/dev/null || stat -f "%Lp" "$TEST_FILE")
if [[ "$perms" != "600" ]]; then
    echo "PASS: Default creation is insecure ($perms)"
else
    echo "WARN: Default umask is already strict (077)? This test assumes default umask allows group/other read."
fi

echo "=== Test 2: Secure Creation (Fix Verification) ==="
rm -f "$TEST_FILE"
# Secure creation
(umask 077; echo "secret" > "$TEST_FILE")
check_permissions "$TEST_FILE" "600"

echo "=== Test 3: Existing File (Regression Check) ==="
rm -f "$TEST_FILE"
# Create with 644
echo "old content" > "$TEST_FILE"
chmod 644 "$TEST_FILE"

# Try to overwrite with umask 077 (simulating the fix applied blindly)
(umask 077; echo "new content" > "$TEST_FILE")
# Should still be 644 because file existed
if check_permissions "$TEST_FILE" "644"; then
    echo "Confirmed: Overwriting existing file preserves insecure permissions (Must delete file first!)"
else
    echo "Unexpected: Permissions changed to $perms?"
fi

rm -f "$TEST_FILE"
