#!/bin/bash
#
# setup-ssh-keys.sh - Generate SSH keys and store in 1Password
#
# Usage:
#   ./tools/setup-ssh-keys.sh              # Generate and store SSH key
#   ./tools/setup-ssh-keys.sh --help       # Show help
#
# This script:
#   1. Generates an Ed25519 SSH key pair
#   2. Stores the private key in 1Password
#   3. Displays the public key to add to GitHub/GitLab
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

say() { echo -e "${GREEN}[ssh]${NC} $1"; }
info() { echo -e "${BLUE}→${NC} $1"; }
warn() { echo -e "${YELLOW}!${NC} $1"; }
error() { echo -e "${RED}[ssh] ERROR:${NC} $1" >&2; exit 1; }

show_help() {
    echo -e "${BOLD}setup-ssh-keys${NC} - Generate SSH keys and store in 1Password"
    echo ""
    echo -e "${BOLD}Usage:${NC}"
    echo "  ./tools/setup-ssh-keys.sh [options]"
    echo ""
    echo -e "${BOLD}Options:${NC}"
    echo "  --vault NAME    1Password vault (default: development)"
    echo "  --name NAME     Key name in 1Password (default: SSH Key)"
    echo "  --help          Show this help"
    echo ""
    echo -e "${BOLD}What this does:${NC}"
    echo "  1. Generates an Ed25519 SSH key pair"
    echo "  2. Stores the private key in 1Password"
    echo "  3. Configures SSH to use 1Password agent (optional)"
    echo ""
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --vault) VAULT="$2"; shift 2 ;;
        --name) KEY_NAME="$2"; shift 2 ;;
        --help|-h) show_help; exit 0 ;;
        *) error "Unknown option: $1" ;;
    esac
done

# Check prerequisites
if ! command -v op &>/dev/null; then
    error "1Password CLI (op) not installed. Run: brew install 1password-cli"
fi

if ! op account list &>/dev/null; then
    error "Not signed in to 1Password. Run: op signin"
fi

echo -e "${BOLD}SSH Key Setup with 1Password${NC}"
echo ""

# Check if key already exists in 1Password
if op item get "$KEY_NAME" --vault "$VAULT" &>/dev/null; then
    warn "SSH key '$KEY_NAME' already exists in vault '$VAULT'"
    echo ""
    read -rp "Overwrite existing key? [y/N]: " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        say "Aborted"
        exit 0
    fi
    op item delete "$KEY_NAME" --vault "$VAULT"
fi

# Create SSH directory
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Generate SSH key directly in 1Password
say "Generating Ed25519 SSH key in 1Password (vault: $VAULT)..."

op item create \
    --category SSH_KEY \
    --vault "$VAULT" \
    --title "$KEY_NAME" \
    --ssh-generate-key ed25519 \
    >/dev/null

say "SSH key generated and stored in 1Password!"

# Retrieve the public key to display
PUBLIC_KEY=$(op read "op://$VAULT/$KEY_NAME/public_key")

# Display public key
echo ""
echo -e "${BOLD}Public Key (add to GitHub/GitLab):${NC}"
echo ""
echo "$PUBLIC_KEY"
echo ""

# Instructions
echo -e "${BOLD}Next steps:${NC}"
echo "  1. Copy the public key above"
echo "  2. Add it to GitHub: https://github.com/settings/ssh/new"
echo "  3. Add it to GitLab: https://gitlab.com/-/profile/keys"
echo ""
echo -e "${BOLD}To restore SSH key on a new machine:${NC}"
echo "  chezmoi apply  # Key will be restored from 1Password"
echo ""

# Ask about 1Password SSH agent
echo -e "${BOLD}1Password SSH Agent:${NC}"
echo "1Password can act as your SSH agent, so you never need the private key on disk."
echo "This is more secure but requires 1Password to be running."
echo ""
read -rp "Enable 1Password SSH agent? [Y/n]: " use_agent

if [[ "$use_agent" != "n" && "$use_agent" != "N" ]]; then
    say "To enable 1Password SSH agent:"
    echo "  1. Open 1Password app → Settings → Developer"
    echo "  2. Enable 'Use the SSH agent'"
    echo "  3. Enable 'Integrate with 1Password CLI'"
    echo ""
    info "Your SSH config will be set up to use the 1Password agent"
fi

say "SSH key setup complete!"
