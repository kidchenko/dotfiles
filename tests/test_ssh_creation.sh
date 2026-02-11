#!/bin/bash
set -e

# Setup mock environment
TEST_HOME=$(mktemp -d)
export HOME="$TEST_HOME"
export XDG_CONFIG_HOME="$TEST_HOME/.config"
mkdir -p "$XDG_CONFIG_HOME/dotfiles"

# Create a wrapper script for op because export -f might not work if script calls op directly via PATH
mkdir -p "$TEST_HOME/bin"
cat <<'EOF' > "$TEST_HOME/bin/op"
#!/bin/bash
mock_op() {
    if [[ "$1" == "account" && "$2" == "list" ]]; then
        return 0 # Simulate signed in
    elif [[ "$1" == "item" && "$2" == "get" ]]; then
        return 0 # Simulate key exists
    elif [[ "$1" == "read" ]]; then
        if [[ "$2" == *"private_key"* ]]; then
            echo "mock-private-key-content"
        else
            echo "mock-public-key-content"
        fi
    else
        echo "mock-op-called-with: $@" >&2
        return 0
    fi
}
mock_op "$@"
EOF
chmod +x "$TEST_HOME/bin/op"
export PATH="$TEST_HOME/bin:$PATH"

# Setup yq mock if needed (script uses yq to read config)
# But we pass --vault and --name so it might skip config reading or use defaults.
# If yq is missing, script might fail or fallback.
# load_config checks command -v yq.
# Let's verify if yq is installed in the environment.
if ! command -v yq &>/dev/null; then
    # Mock yq
    cat <<'EOF' > "$TEST_HOME/bin/yq"
#!/bin/bash
echo "null"
EOF
    chmod +x "$TEST_HOME/bin/yq"
fi

# Run the restore command
# We use --vault and --name to bypass interactive prompt if needed.
# Since local key doesn't exist, cmd_restore should run without prompting for overwrite.

echo "Running setup-ssh-keys.sh restore..."
./tools/setup-ssh-keys.sh restore --vault test --name test-key

# Check permissions
KEY_FILE="$TEST_HOME/.ssh/id_ed25519"
SSH_DIR="$TEST_HOME/.ssh"

if [[ ! -f "$KEY_FILE" ]]; then
    echo "FAIL: Key file not created"
    exit 1
fi

PERMS=$(stat -c "%a" "$KEY_FILE")
if [[ "$PERMS" != "600" ]]; then
    echo "FAIL: Private key permissions are $PERMS (expected 600)"
    exit 1
fi

DIR_PERMS=$(stat -c "%a" "$SSH_DIR")
if [[ "$DIR_PERMS" != "700" ]]; then
    echo "FAIL: SSH directory permissions are $DIR_PERMS (expected 700)"
    exit 1
fi

echo "PASS: SSH key creation secure"
rm -rf "$TEST_HOME"
