#!/bin/bash
#
# setup-ssh-keys.sh - Manage SSH keys with 1Password
#
# Usage:
#   ./tools/setup-ssh-keys.sh              # Interactive: restore or generate
#   ./tools/setup-ssh-keys.sh restore      # Restore SSH key from 1Password
#   ./tools/setup-ssh-keys.sh generate     # Generate new SSH key in 1Password
#   ./tools/setup-ssh-keys.sh show         # Show local public key
#   ./tools/setup-ssh-keys.sh compare      # Compare local vs 1Password keys
#   ./tools/setup-ssh-keys.sh --help       # Show help
#

set -e

# Colors
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' BOLD='' NC=''
fi

# Configuration file
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/config.yaml"

# Default configuration (can be overridden by config.yaml or CLI args)
VAULT="development"
KEY_NAME="SSH Key"
KEY_TYPE="ed25519"
SSH_DIR="$HOME/.ssh"

# Load configuration from config.yaml
load_config() {
    if [[ -f "$CONFIG_FILE" ]] && command -v yq &>/dev/null; then
        local val
        val=$(yq -r '.ssh.vault // ""' "$CONFIG_FILE" 2>/dev/null)
        [[ -n "$val" && "$val" != "null" ]] && VAULT="$val"

        val=$(yq -r '.ssh.item_name // ""' "$CONFIG_FILE" 2>/dev/null)
        [[ -n "$val" && "$val" != "null" ]] && KEY_NAME="$val"

        val=$(yq -r '.ssh.key_type // ""' "$CONFIG_FILE" 2>/dev/null)
        [[ -n "$val" && "$val" != "null" ]] && KEY_TYPE="$val"
    fi

    # Set paths based on key type
    PRIVATE_KEY_FILE="$SSH_DIR/id_$KEY_TYPE"
    PUBLIC_KEY_FILE="$SSH_DIR/id_$KEY_TYPE.pub"
}

load_config

say() { echo -e "${GREEN}[ssh]${NC} $1"; }
info() { echo -e "${BLUE}→${NC} $1"; }
warn() { echo -e "${YELLOW}!${NC} $1"; }
error() { echo -e "${RED}[ssh] ERROR:${NC} $1" >&2; exit 1; }

show_help() {
    echo -e "${BOLD}setup-ssh-keys${NC} - Manage SSH keys with 1Password"
    echo ""
    echo -e "${BOLD}Usage:${NC}"
    echo "  dotfiles ssh [command] [options]"
    echo ""
    echo -e "${BOLD}Commands:${NC}"
    echo "  (none)          Interactive mode - restore if exists, otherwise generate"
    echo "  sync            Auto-sync: restore if missing, prompt only if keys differ"
    echo "  restore         Restore SSH key from 1Password to ~/.ssh/"
    echo "  generate        Generate new SSH key and store in 1Password"
    echo "  show            Show local public key"
    echo "  compare         Compare local key with 1Password"
    echo ""
    echo -e "${BOLD}Options:${NC}"
    echo "  --vault NAME    1Password vault (default: development)"
    echo "  --name NAME     Key name in 1Password (default: SSH Key)"
    echo "  --help          Show this help"
    echo ""
    echo -e "${BOLD}Examples:${NC}"
    echo "  dotfiles ssh                  # Interactive setup"
    echo "  dotfiles ssh restore          # Restore key from 1Password"
    echo "  dotfiles ssh generate         # Generate new key"
    echo "  dotfiles ssh show             # Display local public key"
    echo "  dotfiles ssh compare          # Check if local matches 1Password"
    echo ""
}

# Get the command (first non-option argument)
COMMAND=""
ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        --vault) VAULT="$2"; shift 2 ;;
        --name) KEY_NAME="$2"; shift 2 ;;
        --help|-h) show_help; exit 0 ;;
        -*) error "Unknown option: $1" ;;
        *)
            if [[ -z "$COMMAND" ]]; then
                COMMAND="$1"
            else
                ARGS+=("$1")
            fi
            shift
            ;;
    esac
done

# Check prerequisites
check_prerequisites() {
    if ! command -v op &>/dev/null; then
        error "1Password CLI (op) not installed. Run: brew install 1password-cli"
    fi

    if ! op account list &>/dev/null; then
        error "Not signed in to 1Password. Run: op signin"
    fi
}

# Check if key exists in 1Password
key_exists_in_1password() {
    op item get "$KEY_NAME" --vault "$VAULT" &>/dev/null
}

# Check if key exists locally
key_exists_locally() {
    [[ -f "$PRIVATE_KEY_FILE" ]]
}

# Restore SSH key from 1Password
cmd_restore() {
    check_prerequisites

    if ! key_exists_in_1password; then
        error "SSH key '$KEY_NAME' not found in 1Password vault '$VAULT'. Run 'dotfiles ssh generate' first."
    fi

    if key_exists_locally; then
        warn "SSH key already exists at $PRIVATE_KEY_FILE"
        read -rp "Overwrite local key? [y/N]: " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            say "Aborted"
            exit 0
        fi
    fi

    say "Restoring SSH key from 1Password..."

    # Create SSH directory
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"

    # Read private key from 1Password and save locally (with secure permissions)
    (
        umask 077
        op read "op://$VAULT/$KEY_NAME/private_key" > "$PRIVATE_KEY_FILE"
    )

    # Read public key from 1Password and save locally
    op read "op://$VAULT/$KEY_NAME/public_key" > "$PUBLIC_KEY_FILE"
    chmod 644 "$PUBLIC_KEY_FILE"

    say "SSH key restored to $SSH_DIR"
    echo ""
    info "Public key:"
    cat "$PUBLIC_KEY_FILE"
    echo ""
}

# Generate new SSH key in 1Password
cmd_generate() {
    check_prerequisites

    echo -e "${BOLD}SSH Key Generation with 1Password${NC}"
    echo ""

    # Check if key already exists in 1Password
    if key_exists_in_1password; then
        warn "SSH key '$KEY_NAME' already exists in vault '$VAULT'"
        echo ""
        read -rp "Overwrite existing key? [y/N]: " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            say "Aborted"
            exit 0
        fi
        op item delete "$KEY_NAME" --vault "$VAULT"
    fi

    # Generate SSH key directly in 1Password
    say "Generating $KEY_TYPE SSH key in 1Password (vault: $VAULT)..."

    op item create \
        --category SSH_KEY \
        --vault "$VAULT" \
        --title "$KEY_NAME" \
        --ssh-generate-key "$KEY_TYPE" \
        >/dev/null

    say "SSH key generated and stored in 1Password!"

    # Show the public key
    cmd_show

    # Instructions
    echo -e "${BOLD}Next steps:${NC}"
    echo "  1. Copy the public key above"
    echo "  2. Add it to GitHub: https://github.com/settings/ssh/new"
    echo "  3. Add it to GitLab: https://gitlab.com/-/profile/keys"
    echo "  4. Run 'dotfiles ssh restore' to save key locally"
    echo ""

    # Ask about 1Password SSH agent
    echo -e "${BOLD}1Password SSH Agent (optional):${NC}"
    echo "1Password can act as your SSH agent, so you never need the private key on disk."
    echo "To enable: 1Password app → Settings → Developer → Enable SSH agent"
    echo ""
}

# Show local public key
cmd_show() {
    if ! key_exists_locally; then
        error "No local SSH key found at $PUBLIC_KEY_FILE"
    fi

    echo ""
    echo -e "${BOLD}Local Public Key:${NC} ($PUBLIC_KEY_FILE)"
    echo ""
    cat "$PUBLIC_KEY_FILE"
    echo ""
}

# Compare local key with 1Password
cmd_compare() {
    check_prerequisites

    local has_local=false
    local has_1password=false
    local local_key=""
    local op_key=""

    # Check local key
    if key_exists_locally && [[ -f "$PUBLIC_KEY_FILE" ]]; then
        has_local=true
        local_key=$(cat "$PUBLIC_KEY_FILE")
    fi

    # Check 1Password key
    if key_exists_in_1password; then
        has_1password=true
        op_key=$(op read "op://$VAULT/$KEY_NAME/public_key")
    fi

    echo ""
    echo -e "${BOLD}SSH Key Comparison${NC}"
    echo ""

    # Show status
    if $has_local; then
        echo -e "${GREEN}✓${NC} Local key exists: $PUBLIC_KEY_FILE"
    else
        echo -e "${RED}✗${NC} No local key found"
    fi

    if $has_1password; then
        echo -e "${GREEN}✓${NC} 1Password key exists: $VAULT/$KEY_NAME"
    else
        echo -e "${RED}✗${NC} No key in 1Password vault '$VAULT'"
    fi

    echo ""

    # Show keys
    if $has_local; then
        echo -e "${BOLD}Local:${NC}"
        echo "$local_key"
        echo ""
    fi

    if $has_1password; then
        echo -e "${BOLD}1Password:${NC}"
        echo "$op_key"
        echo ""
    fi

    # Compare if both exist
    if $has_local && $has_1password; then
        if [[ "$local_key" == "$op_key" ]]; then
            echo -e "${GREEN}✓ Keys match!${NC}"
        else
            echo -e "${YELLOW}! Keys are different${NC}"
            info "Run 'dotfiles ssh restore' to sync from 1Password to local"
        fi
    elif $has_1password && ! $has_local; then
        info "Run 'dotfiles ssh restore' to restore key from 1Password"
    elif $has_local && ! $has_1password; then
        warn "Local key exists but not in 1Password"
        info "Consider backing up your key to 1Password"
    else
        info "Run 'dotfiles ssh generate' to create a new key"
    fi

    echo ""
}

# Sync mode - auto-sync if possible, prompt only when needed
cmd_sync() {
    check_prerequisites

    local has_local=false
    local has_1password=false
    local local_key=""
    local op_key=""

    # Check local key
    if key_exists_locally && [[ -f "$PUBLIC_KEY_FILE" ]]; then
        has_local=true
        local_key=$(cat "$PUBLIC_KEY_FILE")
    fi

    # Check 1Password key
    if key_exists_in_1password; then
        has_1password=true
        op_key=$(op read "op://$VAULT/$KEY_NAME/public_key" 2>/dev/null)
    fi

    # Decision logic
    if $has_local && $has_1password; then
        if [[ "$local_key" == "$op_key" ]]; then
            say "SSH keys are in sync ✓"
            return 0
        else
            # Keys differ - ask user
            warn "Local SSH key differs from 1Password"
            echo ""
            echo "Options:"
            echo "  1. Overwrite local with 1Password key"
            echo "  2. Keep local key (do nothing)"
            echo ""
            read -rp "Choose [1-2]: " choice
            case $choice in
                1) cmd_restore ;;
                *) say "Keeping local key" ;;
            esac
        fi
    elif $has_1password && ! $has_local; then
        # Auto-restore from 1Password
        say "Restoring SSH key from 1Password..."
        cmd_restore
    elif $has_local && ! $has_1password; then
        warn "Local SSH key exists but not in 1Password"
        info "Consider backing up your key to 1Password"
    else
        # Neither exists - ask to generate
        say "No SSH key found"
        echo ""
        read -rp "Generate new SSH key in 1Password? [Y/n]: " confirm
        if [[ "$confirm" != "n" && "$confirm" != "N" ]]; then
            cmd_generate
        fi
    fi
}

# Interactive mode
cmd_interactive() {
    check_prerequisites

    echo -e "${BOLD}SSH Key Setup with 1Password${NC}"
    echo ""

    if key_exists_in_1password; then
        say "Found SSH key '$KEY_NAME' in 1Password"

        if key_exists_locally; then
            say "SSH key already exists locally at $PRIVATE_KEY_FILE"
            echo ""
            echo "Options:"
            echo "  1. Show public key"
            echo "  2. Overwrite local key from 1Password"
            echo "  3. Exit"
            echo ""
            read -rp "Choose [1-3]: " choice

            case $choice in
                1) cmd_show ;;
                2) cmd_restore ;;
                *) say "Exiting"; exit 0 ;;
            esac
        else
            echo ""
            read -rp "Restore SSH key from 1Password to local machine? [Y/n]: " confirm
            if [[ "$confirm" != "n" && "$confirm" != "N" ]]; then
                cmd_restore
            fi
        fi
    else
        say "No SSH key found in 1Password"
        echo ""
        read -rp "Generate new SSH key? [Y/n]: " confirm
        if [[ "$confirm" != "n" && "$confirm" != "N" ]]; then
            cmd_generate
        fi
    fi
}

# Main
case "$COMMAND" in
    sync)
        cmd_sync
        ;;
    restore)
        cmd_restore
        ;;
    generate)
        cmd_generate
        ;;
    show)
        cmd_show
        ;;
    compare)
        cmd_compare
        ;;
    "")
        cmd_interactive
        ;;
    *)
        error "Unknown command: $COMMAND. Run with --help for usage."
        ;;
esac
