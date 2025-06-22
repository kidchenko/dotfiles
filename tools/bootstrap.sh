#!/bin/bash

# tools/bootstrap.sh
#
# Main bootstrap script for setting up the dotfiles environment.
# This script will:
# 1. Ensure essential tools like Git are present.
# 2. Set up XDG environment variables for the current session.
# 3. Install Chezmoi if not already present.
# 4. Initialize Chezmoi with the dotfiles repository and apply configurations.
# 5. Install global tools (npm, pip, dotnet) as configured.
# 6. Install VS Code extensions as configured.

# --- Configuration ---
# !!! IMPORTANT: Replace with your actual dotfiles repository URL !!!
# Examples:
#   HTTPS: https://github.com/yourusername/dotfiles.git
#   SSH:   git@github.com:yourusername/dotfiles.git
DOTFILES_REPO_URL="https://github.com/kidchenko/dotfiles.git" # <<< REPLACE THIS

# Script self-awareness
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
REPO_ROOT_DIR="$(dirname "$SCRIPT_DIR")" # Assumes tools/ is one level down from repo root

# --- Global Flags ---
VERBOSE=false
DRY_RUN=false
FORCE_CHEZMOI_INIT=false # Flag to force `chezmoi init` even if already initialized

# --- Helper Functions ---
say() {
    echo "bootstrap: $1"
}

say_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo "bootstrap (verbose): $1"
    fi
}

say_warning() {
    say "WARNING: $1"
}

say_error() {
    say "ERROR: $1" >&2
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

check_essential_deps() {
    say_verbose "Checking essential dependencies..."
    local missing_deps=0
    if ! command_exists git; then
        say_error "Git is not installed. Git is required to proceed."
        missing_deps=$((missing_deps + 1))
    fi
    if ! command_exists curl && ! command_exists wget; then
        say_error "Neither curl nor wget is installed. One is required to download Chezmoi."
        missing_deps=$((missing_deps + 1))
    fi
    # yq is checked by install_global_tools.sh if needed, but we can check early too
    if ! command_exists yq; then
        say_warning "'yq' (YAML processor) is not installed. It's needed for installing global tools from config.yaml."
        say_warning "Attempting to install yq via common package managers if needed later, or please install it manually."
        # The install_global_tools.sh script will error out if yq is truly needed and missing.
    fi


    if [ "$missing_deps" -gt 0 ]; then
        say_error "Please install the missing essential dependencies and try again."
        exit 1
    fi
    say_verbose "Essential dependencies found."
}

# Function to attempt yq installation (best effort)
install_yq_if_needed() {
    if command_exists yq; then
        say_verbose "yq is already installed."
        return 0
    fi

    say "Attempting to install yq (YAML parser)..."
    if command_exists brew; then
        say "Using Homebrew to install yq..."
        if brew install yq; then say "yq installed via Homebrew."; return 0; else say_warning "Failed to install yq via Homebrew."; fi
    elif command_exists apt-get; then
        say "Using apt-get to install yq (will require sudo)..."
        if sudo apt-get update && sudo apt-get install -y yq; then say "yq installed via apt-get."; return 0; else say_warning "Failed to install yq via apt-get."; fi
    elif command_exists snap; then
        say "Using Snap to install yq (will require sudo if not already configured)..."
        if sudo snap install yq; then say "yq installed via Snap."; return 0; else say_warning "Failed to install yq via Snap."; fi
    elif command_exists dnf; then
        say "Using dnf to install yq (will require sudo)..."
        if sudo dnf install -y yq; then say "yq installed via dnf."; return 0; else say_warning "Failed to install yq via dnf."; fi
    elif command_exists yum; then
        say "Using yum to install yq (will require sudo)..."
        if sudo yum install -y yq; then say "yq installed via yum."; return 0; else say_warning "Failed to install yq via yum."; fi
    fi
    say_warning "Could not automatically install yq. The 'install_global_tools.sh' script might fail if it needs yq."
    say_warning "Please install yq manually: https://github.com/mikefarah/yq/"
}


# --- Argument Parsing for bootstrap.sh ---
declare -a sub_script_args=() # Arguments to pass to sub-scripts

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --verbose)
            VERBOSE=true
            sub_script_args+=("--verbose")
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            sub_script_args+=("--dry-run")
            shift
            ;;
        --force-chezmoi-init)
            FORCE_CHEZMOI_INIT=true
            shift
            ;;
        --repo)
            if [ -n "$2" ]; then
                DOTFILES_REPO_URL="$2"
                shift 2
            else
                say_error "--repo option requires a URL argument."
                exit 1
            fi
            ;;
        -h|--help)
            echo "Usage: $0 [--verbose] [--dry-run] [--force-chezmoi-init] [--repo <URL>]"
            echo "  --verbose             Enable verbose output for bootstrap and sub-scripts."
            echo "  --dry-run             Simulate installations/changes for bootstrap and sub-scripts."
            echo "  --force-chezmoi-init  Force 'chezmoi init' even if already initialized."
            echo "  --repo <URL>          Specify the dotfiles repository URL for Chezmoi."
            echo "                        (Defaults to: $DOTFILES_REPO_URL)"
            echo "  -h, --help            Show this help message."
            exit 0
            ;;
        *)
            say_error "Unknown parameter passed to bootstrap: $1"
            exit 1
            ;;
    esac
done

# --- Main Bootstrap Logic ---
main() {
    say "Starting Bootstrap Process..."
    say "Repository: $DOTFILES_REPO_URL"
    if [ "$DRY_RUN" = true ]; then say "DRY RUN MODE ENABLED"; fi
    if [ "$VERBOSE" = true ]; then say "VERBOSE MODE ENABLED"; fi
    echo # Blank line for readability

    # 1. Check essential dependencies (Git, curl/wget)
    say_verbose "Step 1: Checking essential dependencies..."
    check_essential_deps
    say_verbose "Essential dependency check complete."
    echo

    # 2. Source XDG setup script
    say_verbose "Step 2: Setting up XDG environment variables for this session..."

    # shellcheck source=./tools/xdg_setup.sh
    if source "$SCRIPT_DIR/xdg_setup.sh"; then
        say_verbose "XDG environment variables sourced."
    else
        say_error "Failed to source xdg_setup.sh. This is critical."
        exit 1
    fi
    echo

    # 3. Install Chezmoi
    say_verbose "Step 3: Ensuring Chezmoi is installed..."
    if [ "$DRY_RUN" = true ]; then
        say "DRY RUN: Would run tools/run_once_install-chezmoi.sh"
        if ! command_exists chezmoi; then
             say "DRY RUN: Chezmoi is not currently installed."
        fi
    else
        if "$SCRIPT_DIR/run_once_install-chezmoi.sh"; then
            say_verbose "Chezmoi installation check complete."
        else
            say_error "Failed to run run_once_install-chezmoi.sh. Cannot proceed without Chezmoi."
            exit 1
        fi
    fi
    # Ensure chezmoi is in PATH for the current script if just installed
    # run_once_install-chezmoi.sh attempts to add it to PATH for current session if installed to ~/.local/bin
    # Re-check:
    if ! command_exists chezmoi && [ "$DRY_RUN" = false ]; then
        say_warning "Chezmoi command still not found after installation script."
        say_warning "You might need to open a new shell or manually add its installation directory to your PATH."
        say_warning "Default install location by script is $HOME/.local/bin"
        # Attempt to add it to PATH for this session if we know where it might be
        if [ -d "$HOME/.local/bin" ] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
            say_verbose "Attempting to add $HOME/.local/bin to PATH for current session."
            export PATH="$HOME/.local/bin:$PATH"
            if ! command_exists chezmoi; then
                 say_error "Still cannot find chezmoi. Please fix PATH issues."
                 exit 1
            fi
            say_verbose "Chezmoi found after PATH adjustment."
        else
             say_error "Cannot find chezmoi. Please ensure it is installed and in your PATH."
             exit 1
        fi
    fi
    echo

    # 4. Initialize and apply Chezmoi
    say_verbose "Step 4: Initializing and applying Chezmoi..."
    local chezmoi_cmd_args=()
    if [ "$VERBOSE" = true ]; then chezmoi_cmd_args+=("--verbose"); fi
    # Dry run for chezmoi apply is --dry-run, for init it's more complex (init doesn't change dest dir files)
    # `chezmoi init --apply` is the goal.
    # If already initialized, `chezmoi apply` is sufficient.
    # Chezmoi state file: $XDG_CONFIG_HOME/chezmoi/chezmoi.state.boltdb or similar.
    # Config file: $XDG_CONFIG_HOME/chezmoi/chezmoi.toml

    CHEZMOI_CONFIG_FILE_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/chezmoi/chezmoi.toml"
    CHEZMOI_SOURCE_DIR_PATH="${XDG_DATA_HOME:-$HOME/.local/share}/chezmoi"

    if [ "$DRY_RUN" = true ]; then
        say "DRY RUN: Would initialize/apply Chezmoi."
        say "DRY RUN: Chezmoi command would be something like: chezmoi init --apply $DOTFILES_REPO_URL ${chezmoi_cmd_args[*]}"
        # In dry run, we can't easily check if it *would* apply changes,
        # but `chezmoi -n apply` can show what would happen.
        if command_exists chezmoi; then
            say "DRY RUN: Simulating 'chezmoi -n apply' to see potential changes:"
            chezmoi -n apply "${chezmoi_cmd_args[@]}" || say_warning "Dry run of 'chezmoi -n apply' indicated issues or no changes."
        fi
    else
        if [ "$FORCE_CHEZMOI_INIT" = true ] || [ ! -d "$CHEZMOI_SOURCE_DIR_PATH/.git" ] || [ ! -f "$CHEZMOI_CONFIG_FILE_PATH" ]; then
            say "Chezmoi not initialized or forcing init. Running 'chezmoi init --apply $DOTFILES_REPO_URL'..."
            if chezmoi init --apply "$DOTFILES_REPO_URL" "${chezmoi_cmd_args[@]}"; then
                say "Chezmoi initialized and applied successfully."
            else
                say_error "Chezmoi init --apply failed."
                exit 1
            fi
        else
            say "Chezmoi already initialized. Running 'chezmoi apply'..."
            # Add --refresh-externals if using externals that need updating
            if chezmoi apply "${chezmoi_cmd_args[@]}"; then # Add --refresh-externals if needed
                say "Chezmoi apply successful."
            else
                say_error "Chezmoi apply failed."
                # Optionally, try `chezmoi update` if apply fails due to merge conflicts or outdated source
                # say "Attempting 'chezmoi update'..."
                # if chezmoi update "${chezmoi_cmd_args[@]}"; then
                #    say "'chezmoi update' successful. Please re-run bootstrap or 'chezmoi apply' manually."
                # else
                #    say_error "'chezmoi update' also failed."
                # fi
                exit 1
            fi
        fi
        # After apply, important environment variables (like those in .profile) might have changed.
        # For the rest of *this script's execution*, they won't be updated unless sourced again.
        # xdg_setup.sh already set them for this script's context.
        # Zsh specific files like .zshrc would need a new shell to take effect.
        say_verbose "Dotfiles applied. Shell profiles (e.g., .profile, .zshrc) are updated."
        say_verbose "For full effect (new PATH, env vars from profiles), a new shell session might be needed after bootstrap completes."
    fi
    echo

    # 5. Install yq if needed (for install_global_tools.sh)
    # This is a good place as chezmoi might have placed a config for a package manager.
    say_verbose "Step 5: Ensuring yq (YAML parser) is available..."
    if [ "$DRY_RUN" = true ]; then
        say "DRY RUN: Would check and potentially install yq."
    else
        install_yq_if_needed
    fi
    echo

    # 6. Install Global Tools
    say_verbose "Step 6: Installing global tools..."
    # Pass relevant args like --verbose, --dry-run to the script
    if "$SCRIPT_DIR/install_global_tools.sh" "${sub_script_args[@]}"; then
        say_verbose "Global tools installation script finished."
    else
        say_warning "Global tools installation script reported errors. Check output above."
        # Not necessarily fatal for bootstrap, so continue.
    fi
    echo

    # 7. Install VS Code Extensions
    say_verbose "Step 7: Installing VS Code extensions..."
    if "$SCRIPT_DIR/install_vscode_extensions.sh" "${sub_script_args[@]}"; then
        say_verbose "VS Code extension installation script finished."
    else
        say_warning "VS Code extension installation script reported errors. Check output above."
        # Not fatal.
    fi
    echo

    # 8. Remove old setup.sh if it exists (as it's now superseded)
    OLD_SETUP_SH="$REPO_ROOT_DIR/setup.sh"
    if [ -f "$OLD_SETUP_SH" ]; then
        say_verbose "Step 8: Removing old setup.sh..."
        if [ "$DRY_RUN" = true ]; then
            say "DRY RUN: Would remove $OLD_SETUP_SH"
        else
            if rm -f "$OLD_SETUP_SH"; then
                say "Old setup.sh removed."
                # Also remove it from git if it's tracked. This script shouldn't do git operations on the repo itself.
                # User should `git rm setup.sh` manually from their working copy.
                say_warning "If 'setup.sh' was tracked by Git, please remove it manually using 'git rm setup.sh' and commit."
            else
                say_warning "Failed to remove old setup.sh at $OLD_SETUP_SH."
            fi
        fi
    fi
    echo


    say "Bootstrap Process Completed!"
    if [ "$DRY_RUN" = true ]; then
        say "DRY RUN MODE: No actual changes were made to the system by this script directly (sub-scripts simulated changes)."
    fi
    say "Please open a new shell/terminal session for all changes (especially PATH and shell configurations) to take full effect."
}

# --- Execute Main ---
main

exit 0
