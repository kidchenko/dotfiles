#!/bin/bash
set -e

# Setup mock environment
TEST_DIR="$(mktemp -d)"
MOCK_BIN="$TEST_DIR/bin"
mkdir -p "$MOCK_BIN"
export PATH="$MOCK_BIN:$PATH"

# Mock 'op'
cat << 'EOF' > "$MOCK_BIN/op"
#!/bin/bash
if [[ "$1" == "item" && "$2" == "get" ]]; then
    # Pretend key exists in 1Password
    exit 0
elif [[ "$1" == "read" ]]; then
    echo "dummy-key-content"
    exit 0
else
    # Allow other commands (like account list)
    exit 0
fi
EOF
chmod +x "$MOCK_BIN/op"

# Mock 'chmod' to inspect permissions
cat << 'EOF' > "$MOCK_BIN/chmod"
#!/bin/bash
target="${@: -1}"
if [[ -f "$target" ]]; then
    perms=$(ls -l "$target" | awk '{print $1}')
    echo "MOCK CHMOD: Inspecting $target before chmod: $perms"
fi
# Do nothing (mocked) or actually change permissions?
# If we do nothing, the file remains with creation permissions.
# This helps us verify the umask effect.
EOF
chmod +x "$MOCK_BIN/chmod"

# Set up test environment
export HOME="$TEST_DIR"
export XDG_CONFIG_HOME="$TEST_DIR/.config"
export XDG_DATA_HOME="$TEST_DIR/.local/share"
export XDG_STATE_HOME="$TEST_DIR/.local/state"

# Create config file
mkdir -p "$XDG_CONFIG_HOME/dotfiles"
echo "ssh:
  vault: development
  item_name: SSH Key
  key_type: ed25519" > "$XDG_CONFIG_HOME/dotfiles/config.yaml"

# Run the script
# We expect it to restore the key
echo "Running tools/setup-ssh-keys.sh restore..."
# We pipe 'y' to confirm overwrite if prompted (though initial restore shouldn't need it)
echo "y" | ./tools/setup-ssh-keys.sh restore

# Verify output
# The output should contain "MOCK CHMOD: Inspecting ... before chmod: -rw-r--r--" for private key (if vulnerable)
# or "-rw-------" (if secure)

# Cleanup
rm -rf "$TEST_DIR"
