#!/bin/bash
set -e

# Setup mock environment
TEST_DIR="$PWD/tests/tmp"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR/home"
mkdir -p "$TEST_DIR/bin"

# Mock op
cat << 'EOF' > "$TEST_DIR/bin/op"
#!/bin/bash
if [[ "$1" == "read" ]]; then
    echo "MOCK PRIVATE KEY CONTENT"
elif [[ "$1" == "account" ]]; then
    exit 0
elif [[ "$1" == "item" && "$2" == "get" ]]; then
    exit 0
fi
EOF
chmod +x "$TEST_DIR/bin/op"

# Mock chmod to do nothing, so we can see the permissions at creation
cat << 'EOF' > "$TEST_DIR/bin/chmod"
#!/bin/bash
# no-op
echo "MOCK CHMOD: $@"
EOF
chmod +x "$TEST_DIR/bin/chmod"

export PATH="$TEST_DIR/bin:$PATH"
export HOME="$TEST_DIR/home"
export XDG_CONFIG_HOME="$HOME/.config"

# Create config
mkdir -p "$XDG_CONFIG_HOME/dotfiles"
echo "ssh: { vault: 'test', item_name: 'testkey' }" > "$XDG_CONFIG_HOME/dotfiles/config.yaml"

echo "Running setup-ssh-keys.sh with mocked chmod..."

# Run the script
./tools/setup-ssh-keys.sh restore > "$TEST_DIR/output.log" 2>&1 || true

# Check permissions of the private key
KEY_FILE="$TEST_DIR/home/.ssh/id_ed25519"

if [[ ! -f "$KEY_FILE" ]]; then
    echo "FAIL: Key file not found at $KEY_FILE"
    exit 1
fi

# Get permissions (Linux stat)
PERMS=$(stat -c "%a" "$KEY_FILE")
echo "File permissions detected: $PERMS"

if [[ "$PERMS" == "600" ]]; then
    echo "SECURE: File created with secure permissions (600)"
    exit 0
else
    echo "VULNERABILITY CONFIRMED: File created with insecure permissions ($PERMS)"
    exit 1
fi
