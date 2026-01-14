#!/bin/bash
#
# install-global-tools.sh
#
# Installs global tools from ~/.config/dotfiles/config.yaml

set -e

# Configuration
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/config.yaml"

# Options
DRY_RUN=false

# Colors
if [[ -t 1 ]]; then
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    DIM='\033[2m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    GREEN='' YELLOW='' BLUE='' CYAN='' DIM='' BOLD='' NC=''
fi

# Platform-specific prefixes
node_say() { echo -e "${GREEN}[node]${NC} $1"; }
python_say() { echo -e "${BLUE}[python]${NC} $1"; }
dotnet_say() { echo -e "${CYAN}[dotnet]${NC} $1"; }
warn() { echo -e "${YELLOW}!${NC} $1"; }

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true ;;
        -h|--help)
            echo "Usage: $0 [--dry-run]"
            echo ""
            echo "Installs global tools from config.yaml"
            echo ""
            echo "Options:"
            echo "  --dry-run    Preview without installing"
            exit 0
            ;;
        *) ;;
    esac
    shift
done

# Check dependencies
if ! command -v yq &>/dev/null; then
    warn "yq not installed. Install with: brew install yq"
    exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
    warn "Config file not found: $CONFIG_FILE"
    exit 1
fi

# Collect packages from config
npm_packages=$(yq -r '.global_tools.npm[]?' "$CONFIG_FILE" 2>/dev/null | grep -v '^null$' || true)
pip_packages=$(yq -r '.global_tools.pip[]?' "$CONFIG_FILE" 2>/dev/null | grep -v '^null$' || true)
dotnet_packages=$(yq -r '.global_tools.dotnet[]?' "$CONFIG_FILE" 2>/dev/null | grep -v '^null$' || true)

# Track results
npm_installed=()
pip_installed=()
dotnet_installed=()
failed=()

# --- NPM ---
if [[ -n "$npm_packages" ]]; then
    echo ""
    node_say "${BOLD}Installing Node.js packages${NC}"
    echo -e "${DIM}Packages: $(echo $npm_packages | tr '\n' ' ')${NC}"
    echo ""

    if ! command -v npm &>/dev/null; then
        warn "npm not installed, skipping Node.js packages"
    else
        while IFS= read -r pkg; do
            [[ -z "$pkg" ]] && continue

            if [[ "$DRY_RUN" == true ]]; then
                echo "  → Would install: $pkg"
            else
                echo -n "  Installing $pkg... "
                if npm install -g "$pkg" &>/dev/null; then
                    echo -e "${GREEN}✓${NC}"
                    npm_installed+=("$pkg")
                else
                    echo -e "${YELLOW}✗${NC}"
                    failed+=("npm:$pkg")
                fi
            fi
        done <<< "$npm_packages"
    fi

    if [[ "$DRY_RUN" != true && ${#npm_installed[@]} -gt 0 ]]; then
        echo ""
        node_say "Installed ${#npm_installed[@]} packages: ${npm_installed[*]}"
    fi
fi

# --- Python ---
if [[ -n "$pip_packages" ]]; then
    echo ""
    python_say "${BOLD}Installing Python packages${NC}"
    echo -e "${DIM}Packages: $(echo $pip_packages | tr '\n' ' ')${NC}"
    echo ""

    pip_cmd=""
    if command -v pip3 &>/dev/null; then
        pip_cmd="pip3"
    elif command -v pip &>/dev/null; then
        pip_cmd="pip"
    fi

    if [[ -z "$pip_cmd" ]]; then
        warn "pip not installed, skipping Python packages"
    else
        while IFS= read -r pkg; do
            [[ -z "$pkg" ]] && continue

            if [[ "$DRY_RUN" == true ]]; then
                echo "  → Would install: $pkg"
            else
                echo -n "  Installing $pkg... "
                if $pip_cmd install --user "$pkg" &>/dev/null; then
                    echo -e "${GREEN}✓${NC}"
                    pip_installed+=("$pkg")
                else
                    echo -e "${YELLOW}✗${NC}"
                    failed+=("pip:$pkg")
                fi
            fi
        done <<< "$pip_packages"
    fi

    if [[ "$DRY_RUN" != true && ${#pip_installed[@]} -gt 0 ]]; then
        echo ""
        python_say "Installed ${#pip_installed[@]} packages: ${pip_installed[*]}"
    fi
fi

# --- .NET ---
if [[ -n "$dotnet_packages" ]]; then
    echo ""
    dotnet_say "${BOLD}Installing .NET tools${NC}"
    echo -e "${DIM}Tools: $(echo $dotnet_packages | tr '\n' ' ')${NC}"
    echo ""

    if ! command -v dotnet &>/dev/null; then
        warn "dotnet not installed, skipping .NET tools"
    else
        while IFS= read -r pkg; do
            [[ -z "$pkg" ]] && continue

            if [[ "$DRY_RUN" == true ]]; then
                echo "  → Would install: $pkg"
            else
                echo -n "  Installing $pkg... "
                if dotnet tool install --global "$pkg" &>/dev/null 2>&1; then
                    echo -e "${GREEN}✓${NC}"
                    dotnet_installed+=("$pkg")
                elif dotnet tool list --global 2>/dev/null | grep -iq "^$pkg "; then
                    echo -e "${GREEN}✓${NC} (already installed)"
                    dotnet_installed+=("$pkg")
                else
                    echo -e "${YELLOW}✗${NC}"
                    failed+=("dotnet:$pkg")
                fi
            fi
        done <<< "$dotnet_packages"
    fi

    if [[ "$DRY_RUN" != true && ${#dotnet_installed[@]} -gt 0 ]]; then
        echo ""
        dotnet_say "Installed ${#dotnet_installed[@]} tools: ${dotnet_installed[*]}"
    fi
fi

# --- Summary ---
echo ""
if [[ "$DRY_RUN" == true ]]; then
    echo -e "${BOLD}Dry run complete${NC}"
else
    total=$((${#npm_installed[@]} + ${#pip_installed[@]} + ${#dotnet_installed[@]}))
    echo -e "${BOLD}Global tools installation complete${NC}"
    echo -e "  ${GREEN}✓${NC} $total packages installed"

    if [[ ${#failed[@]} -gt 0 ]]; then
        echo -e "  ${YELLOW}!${NC} ${#failed[@]} failed: ${failed[*]}"
    fi
fi
echo ""
