#!/bin/bash
set -e

# Setup test environment
TEST_DIR=$(mktemp -d)
export HOME="$TEST_DIR"
export XDG_CONFIG_HOME="$TEST_DIR/.config"
export XDG_DATA_HOME="$TEST_DIR/.local/share"
mkdir -p "$TEST_DIR/.config/dotfiles"
mkdir -p "$TEST_DIR/.local/bin"

# Add mock bin to PATH
export PATH="$TEST_DIR/.local/bin:$PATH"

# Create mock op
cat <<EOF > "$TEST_DIR/.local/bin/op"
#!/bin/bash
if [[ "\$1" == "account" && "\$2" == "list" ]]; then
    exit 0
elif [[ "\$1" == "item" && "\$2" == "get" ]]; then
    exit 0
elif [[ "\$1" == "read" ]]; then
    if [[ "\$2" == *"private_key"* ]]; then
        echo "MOCK_PRIVATE_KEY_CONTENT"
    else
        echo "MOCK_PUBLIC_KEY_CONTENT"
    fi
else
    exit 0
fi
EOF
chmod +x "$TEST_DIR/.local/bin/op"

# Create mock yq (script uses it if available)
cat <<EOF > "$TEST_DIR/.local/bin/yq"
#!/bin/bash
echo "" # Return empty or default
EOF
chmod +x "$TEST_DIR/.local/bin/yq"

echo "Running setup-ssh-keys.sh restore in test environment..."

# Determine absolute path to the tool
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TOOL_PATH="$REPO_ROOT/tools/setup-ssh-keys.sh"

# Run the tool
# Pass --vault and --name to avoid yq dependency issues or defaults
bash "$TOOL_PATH" restore --vault "testvault" --name "testkey"

# Verify permissions
PRIVATE_KEY="$HOME/.ssh/id_ed25519"

if [[ ! -f "$PRIVATE_KEY" ]]; then
    echo "ERROR: Private key not created at $PRIVATE_KEY"
    ls -la "$HOME/.ssh"
    exit 1
fi

PERMS=$(stat -c "%a" "$PRIVATE_KEY" 2>/dev/null || stat -f "%Lp" "$PRIVATE_KEY")

echo "Permissions of private key: $PERMS"

if [[ "$PERMS" != "600" ]]; then
    echo "ERROR: Permissions are not 600!"
    exit 1
fi

echo "SUCCESS: Key created with correct permissions."

# Verify directory permissions
SSH_DIR="$HOME/.ssh"
DIR_PERMS=$(stat -c "%a" "$SSH_DIR" 2>/dev/null || stat -f "%Lp" "$SSH_DIR")
echo "Permissions of .ssh directory: $DIR_PERMS"

if [[ "$DIR_PERMS" != "700" ]]; then
    echo "ERROR: Directory permissions are not 700!"
    exit 1
fi

echo "SUCCESS: Directory created with correct permissions."

# Cleanup
rm -rf "$TEST_DIR"
