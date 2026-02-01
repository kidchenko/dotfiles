#!/bin/bash
set -e

# Setup mock environment
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$TEST_DIR/.." && pwd)"
MOCK_BIN="$TEST_DIR/bin"
TEMP_HOME="$TEST_DIR/temp_home"

# Clean up previous run
rm -rf "$TEMP_HOME"
rm -rf "$MOCK_BIN"
mkdir -p "$TEMP_HOME"
mkdir -p "$MOCK_BIN"

# Mock 'op' command
cat <<EOF > "$MOCK_BIN/op"
#!/bin/bash
if [[ "\$1" == "account" && "\$2" == "list" ]]; then
    exit 0
elif [[ "\$1" == "item" && "\$2" == "get" ]]; then
    exit 0
elif [[ "\$1" == "read" ]]; then
    if [[ "\$2" == *"private_key"* ]]; then
        echo "PRIVATE KEY CONTENT"
    elif [[ "\$2" == *"public_key"* ]]; then
        echo "PUBLIC KEY CONTENT"
    fi
fi
EOF
chmod +x "$MOCK_BIN/op"

# Mock 'yq' command (optional, but good to have)
cat <<EOF > "$MOCK_BIN/yq"
#!/bin/bash
exit 1 # simulate not installed or failing, script handles it
EOF
chmod +x "$MOCK_BIN/yq"

# Add mock bin to PATH
export PATH="$MOCK_BIN:$PATH"
export HOME="$TEMP_HOME"
export XDG_CONFIG_HOME="$TEMP_HOME/.config"

# Run the script
echo "Running setup-ssh-keys.sh restore..."
"$REPO_ROOT/tools/setup-ssh-keys.sh" restore

# Verify files exist
PRIVATE_KEY="$TEMP_HOME/.ssh/id_ed25519"
PUBLIC_KEY="$TEMP_HOME/.ssh/id_ed25519.pub"

if [[ ! -f "$PRIVATE_KEY" ]]; then
    echo "ERROR: Private key not found at $PRIVATE_KEY"
    exit 1
fi

if [[ ! -f "$PUBLIC_KEY" ]]; then
    echo "ERROR: Public key not found at $PUBLIC_KEY"
    exit 1
fi

# Verify permissions
# Private key should be 600 (-rw-------)
PERMS=$(stat -c "%a" "$PRIVATE_KEY" 2>/dev/null || stat -f "%Lp" "$PRIVATE_KEY")
if [[ "$PERMS" != "600" ]]; then
    echo "ERROR: Private key permissions are $PERMS, expected 600"
    exit 1
fi

# Public key should be 644 (-rw-r--r--)
PERMS=$(stat -c "%a" "$PUBLIC_KEY" 2>/dev/null || stat -f "%Lp" "$PUBLIC_KEY")
if [[ "$PERMS" != "644" ]]; then
    echo "ERROR: Public key permissions are $PERMS, expected 644"
    exit 1
fi

echo "SUCCESS: SSH keys restored with correct permissions."

# Cleanup
rm -rf "$TEMP_HOME"
rm -rf "$MOCK_BIN"
