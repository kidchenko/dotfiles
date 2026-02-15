#!/bin/bash
set -e

# Create a temporary directory for the test environment
TEST_HOME=$(mktemp -d)
trap 'rm -rf "$TEST_HOME"' EXIT

# Export HOME to point to the temporary directory
export HOME="$TEST_HOME"

# Also set XDG vars to use temp dir (for safety)
export XDG_CONFIG_HOME="$TEST_HOME/.config"
export XDG_DATA_HOME="$TEST_HOME/.local/share"
export XDG_STATE_HOME="$TEST_HOME/.local/state"

# Setup mock op
mkdir -p "$TEST_HOME/bin"
cat > "$TEST_HOME/bin/op" <<'EOF'
#!/bin/bash
if [[ "$1" == "account" && "$2" == "list" ]]; then
    echo "fake-account"
    exit 0
fi
if [[ "$1" == "item" && "$2" == "get" ]]; then
    exit 0
fi
if [[ "$1" == "read" ]]; then
    echo "fake-key-content"
    exit 0
fi
EOF
chmod +x "$TEST_HOME/bin/op"
export PATH="$TEST_HOME/bin:$PATH"

# Setup config
mkdir -p "$XDG_CONFIG_HOME/dotfiles"
echo "ssh:" > "$XDG_CONFIG_HOME/dotfiles/config.yaml"
echo "  vault: test-vault" >> "$XDG_CONFIG_HOME/dotfiles/config.yaml"
echo "  item_name: test-key" >> "$XDG_CONFIG_HOME/dotfiles/config.yaml"

# Run restore
# We run the script from the repo root
./tools/setup-ssh-keys.sh restore

# Verify file exists in the fake home
if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
    echo "Key restored successfully to $HOME/.ssh/id_ed25519"
else
    echo "Key restore failed"
    exit 1
fi
