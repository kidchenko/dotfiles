#!/bin/bash
#
# setup-ssh-keys.sh - Manage SSH keys with 1Password
#
# Usage:
#   ./tools/setup-ssh-keys.sh              # Interactive: restore or generate
#   ./tools/setup-ssh-keys.sh restore      # Restore SSH key from 1Password
#   ./tools/setup-ssh-keys.sh generate     # Generate new SSH key in 1Password
#   ./tools/setup-ssh-keys.sh show         # Show public key from 1Password
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

# Configuration
VAULT="development"
KEY_NAME="SSH Key"
SSH_DIR="$HOME/.ssh"
PRIVATE_KEY_FILE="$SSH_DIR/id_ed25519"
PUBLIC_KEY_FILE="$SSH_DIR/id_ed25519.pub"

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
    echo "  restore         Restore SSH key from 1Password to ~/.ssh/"
    echo "  generate        Generate new SSH key and store in 1Password"
    echo "  show            Show public key from 1Password"
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
    echo "  dotfiles ssh show             # Display public key"
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

    # Read private key from 1Password and save locally
    op read "op://$VAULT/$KEY_NAME/private_key" > "$PRIVATE_KEY_FILE"
    chmod 600 "$PRIVATE_KEY_FILE"

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
    say "Generating Ed25519 SSH key in 1Password (vault: $VAULT)..."

    op item create \
        --category SSH_KEY \
        --vault "$VAULT" \
        --title "$KEY_NAME" \
        --ssh-generate-key ed25519 \
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

# Show public key from 1Password
cmd_show() {
    check_prerequisites

    if ! key_exists_in_1password; then
        error "SSH key '$KEY_NAME' not found in 1Password vault '$VAULT'"
    fi

    local public_key
    public_key=$(op read "op://$VAULT/$KEY_NAME/public_key")

    echo ""
    echo -e "${BOLD}Public Key:${NC}"
    echo ""
    echo "$public_key"
    echo ""
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
    restore)
        cmd_restore
        ;;
    generate)
        cmd_generate
        ;;
    show)
        cmd_show
        ;;
    "")
        cmd_interactive
        ;;
    *)
        error "Unknown command: $COMMAND. Run with --help for usage."
        ;;
esac
