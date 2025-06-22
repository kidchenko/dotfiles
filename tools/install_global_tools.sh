#!/bin/bash

# tools/install_global_tools.sh
#
# Installs global tools based on the configuration specified in
# ~/.config/dotfiles/config.yaml (or $XDG_CONFIG_HOME/dotfiles/config.yaml).

set -e # Exit on any error

# --- Script Configuration & Variables ---
VERBOSE=false
DRY_RUN=false
CONFIG_FILE_NAME="config.yaml" # Name of the config file within the dotfiles config directory

# Determine config file path using XDG standard
if [ -n "$XDG_CONFIG_HOME" ]; then
    CONFIG_DIR="$XDG_CONFIG_HOME/dotfiles"
else
    CONFIG_DIR="$HOME/.config/dotfiles"
fi
CONFIG_FILE="$CONFIG_DIR/$CONFIG_FILE_NAME"

# --- Helper Functions ---
say() {
    echo "install_global_tools: $1"
}

say_verbose() {
    if [ "$VERBOSE" = true ]; then
        say "$1"
    fi
}

say_warning() {
    say "WARNING: $1"
}

say_error() {
    say "ERROR: $1" >&2
    # exit 1 # Decided by calling function if it's fatal
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if yq is installed (YAML parser)
check_yq() {
    if ! command_exists yq; then
        say_error "YAML parser 'yq' is not installed. This script requires 'yq' to parse $CONFIG_FILE_NAME."
        say_error "Please install yq (e.g., 'brew install yq', 'sudo snap install yq', or download from https://github.com/mikefarah/yq)."
        exit 1
    fi
}

# --- Installation Functions ---

# Install NPM packages
install_npm_package() {
    local package="$1"
    if ! command_exists npm; then
        say_warning "NPM is not installed. Skipping NPM package: $package"
        return 1
    fi

    say_verbose "Checking NPM package: $package..."
    # Idempotency check: npm list -g --depth=0 | grep <package_name>
    # However, npm install -g itself is largely idempotent for installing/updating.
    # A specific check might be `npm list -g --depth=0 ${package%%@*} | grep -q ${package%%@*}`
    # For simplicity, we'll rely on npm's idempotency here. Re-running install will update if needed.

    if [ "$DRY_RUN" = true ]; then
        say "DRY RUN: Would install NPM package: $package (npm install -g $package)"
    else
        say "Installing NPM package: $package..."
        if npm install -g "$package"; then
            say_verbose "NPM package $package installed/updated successfully."
        else
            say_error "Failed to install NPM package: $package"
            return 1 # Non-fatal, continue with other packages
        fi
    fi
}

# Install Pip packages
install_pip_package() {
    local package="$1"
    # Try pip3 first, then pip
    local pip_cmd=""
    if command_exists pip3; then
        pip_cmd="pip3"
    elif command_exists pip; then
        pip_cmd="pip"
    else
        say_warning "Pip (pip3 or pip) is not installed. Skipping Pip package: $package"
        return 1
    fi

    say_verbose "Checking Pip package: $package with $pip_cmd..."
    # Idempotency check: $pip_cmd show <package_name>
    # $pip_cmd install --user is generally idempotent.
    # Example check: $pip_cmd show "${package%%==*}" > /dev/null 2>&1

    if [ "$DRY_RUN" = true ]; then
        say "DRY RUN: Would install Pip package: $package ($pip_cmd install --user $package)"
    else
        say "Installing Pip package: $package (with --user)..."
        if "$pip_cmd" install --user "$package"; then
            say_verbose "Pip package $package installed/updated successfully."
        else
            say_error "Failed to install Pip package: $package"
            return 1 # Non-fatal
        fi
    fi
}

# Install Dotnet tools
install_dotnet_tool() {
    local tool_name="$1" # This is the package name for dotnet tools
    if ! command_exists dotnet; then
        say_warning "Dotnet CLI is not installed. Skipping Dotnet tool: $tool_name"
        return 1
    fi

    say_verbose "Checking Dotnet tool: $tool_name..."
    # Idempotency check: dotnet tool list -g | grep <tool_name_lowercase>
    # Dotnet tool install is idempotent and will update if already installed.
    # Tool names are case-insensitive for the check but package ID is specific.
    # We'll use the provided name.

    if [ "$DRY_RUN" = true ]; then
        say "DRY RUN: Would install Dotnet tool: $tool_name (dotnet tool install --global $tool_name)"
    else
        say "Installing Dotnet tool: $tool_name..."
        # Attempt to update if already installed, otherwise install
        # `dotnet tool update --global "$tool_name"` can be used if we know it's installed.
        # `dotnet tool install --global "$tool_name"` will install or update.
        if dotnet tool install --global "$tool_name"; then
            say_verbose "Dotnet tool $tool_name installed/updated successfully."
        else
            # Sometimes install fails if already installed but update is available. Try update.
            # However, modern `dotnet tool install` should handle updates.
            # If it truly failed, then it's an error.
            say_error "Failed to install/update Dotnet tool: $tool_name. It might already be installed and up-to-date, or an error occurred."
            # Check if it's actually installed now, despite error message (e.g. if it was just a warning)
            if dotnet tool list --global | grep -iq "^${tool_name%% *} "; then # check by package id (first word)
                 say_verbose "Dotnet tool $tool_name appears to be installed despite previous message."
            else
                 return 1 # Non-fatal
            fi
        fi
    fi
}

# --- Main Logic ---
main() {
    say "Starting global tools installation..."

    if [ ! -f "$CONFIG_FILE" ]; then
        say_error "Configuration file not found: $CONFIG_FILE"
        say_error "Please ensure it exists and is populated."
        exit 1
    fi

    check_yq # Ensure yq is available for parsing

    # Process NPM packages
    say_verbose "Processing NPM packages from $CONFIG_FILE..."
    # yq eval '.global_tools.npm[]?' "$CONFIG_FILE" # The '?' suppresses errors for null arrays
    mapfile -t npm_tools < <(yq eval '.global_tools.npm[]?' "$CONFIG_FILE" | grep -v '^null$') # Read into array, filter null
    if [ ${#npm_tools[@]} -gt 0 ]; then
        for tool in "${npm_tools[@]}"; do
            install_npm_package "$tool" || say_verbose "Continuing after failure with $tool"
        done
    else
        say_verbose "No NPM packages listed in $CONFIG_FILE or section is empty/null."
    fi

    # Process Pip packages
    say_verbose "Processing Pip packages from $CONFIG_FILE..."
    mapfile -t pip_tools < <(yq eval '.global_tools.pip[]?' "$CONFIG_FILE" | grep -v '^null$')
    if [ ${#pip_tools[@]} -gt 0 ]; then
        for tool in "${pip_tools[@]}"; do
            install_pip_package "$tool" || say_verbose "Continuing after failure with $tool"
        done
    else
        say_verbose "No Pip packages listed in $CONFIG_FILE or section is empty/null."
    fi

    # Process Dotnet tools
    say_verbose "Processing Dotnet tools from $CONFIG_FILE..."
    mapfile -t dotnet_tools < <(yq eval '.global_tools.dotnet[]?' "$CONFIG_FILE" | grep -v '^null$')
    if [ ${#dotnet_tools[@]} -gt 0 ]; then
        for tool in "${dotnet_tools[@]}"; do
            install_dotnet_tool "$tool" || say_verbose "Continuing after failure with $tool"
        done
    else
        say_verbose "No Dotnet tools listed in $CONFIG_FILE or section is empty/null."
    fi

    say "Global tools installation process finished."
    if [ "$DRY_RUN" = true ]; then
        say "DRY RUN MODE: No actual changes were made."
    fi
}

# --- Argument Parsing ---
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --verbose) VERBOSE=true; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        -h|--help)
            echo "Usage: $0 [--verbose] [--dry-run]"
            echo "  --verbose    Enable verbose output."
            echo "  --dry-run    Simulate installations without making changes."
            echo "  -h, --help   Show this help message."
            echo ""
            echo "This script installs global tools (npm, pip, dotnet) based on $CONFIG_FILE."
            exit 0
            ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
done

# --- Script Execution ---
main "$@"
