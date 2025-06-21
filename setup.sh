#!/bin/bash

REPO=~/kidchenko/dotfiles
# DOTFILES_DIR=${DOTFILES_DIR:-~/.${REPO}}
DOTFILES_DIR=~/.kidchenko/dotfiles
CRON_DIR=~/.kidchenko/dotfiles/cron
CONFIG_FILE=~/.kidchenko/dotfiles/config.yaml

# Logging functions
_log() {
    local level="$1"
    shift
    local message="$*"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message"
}

log_info() {
    _log "INFO" "$@"
}

log_warn() {
    _log "WARN" "$@" >&2
}

log_error() {
    _log "ERROR" "$@" >&2
}

# OS detection functions
_OS_TYPE="" # Cache variable

get_os_type() {
    if [[ -n "$_OS_TYPE" ]]; then
        echo "$_OS_TYPE"
        return
    fi

    if [[ "$(uname)" == "Darwin" ]]; then
        _OS_TYPE="macos"
    elif [[ "$(expr substr $(uname -s) 1 5)" == "Linux" ]]; then
        _OS_TYPE="linux"
    # Add other checks if needed, e.g. for WSL (Windows Subsystem for Linux)
    # elif grep -qE "(Microsoft|WSL)" /proc/version &> /dev/null; then
    #     _OS_TYPE="wsl" # Could be considered a type of linux
    else
        _OS_TYPE="unknown"
    fi
    echo "$_OS_TYPE"
}

is_macos() {
    [[ "$(get_os_type)" == "macos" ]]
}

is_linux() {
    [[ "$(get_os_type)" == "linux" ]]
}

# Function to read values from YAML file
get_config_value() {
    yq eval "$1" "$CONFIG_FILE"
}

# Function to check if a feature flag is enabled
is_feature_enabled() {
    local feature_name="$1"
    local value=$(get_config_value ".feature_flags.$feature_name")
    if [[ "$value" == "true" ]]; then
        return 0 # true
    else
        return 1 # false
    fi
}

ensureFolders() {
    local username=$(get_config_value '.general.username')
    log_info "Using username from config: $username for folder checks (if applicable in future)"

    local DIRS_TO_ENSURE=(
        ~/lambda3
        ~/jetabroad
        ~/thoughtworks
        ~/sevenpeaks
        ~/isho
        ~/kidchenko
    )

    for dir_path in "${DIRS_TO_ENSURE[@]}"; do
        if [[ ! -d "$dir_path" ]]; then
            log_info "Directory $dir_path does not exist. Creating..."
            mkdir -p "$dir_path" || log_error "Failed to create directory $dir_path"
        else
            log_info "Directory $dir_path already exists. Skipping creation."
        fi
    done
}

install_yq() {
    if ! command -v yq &> /dev/null
    then
        log_warn "yq could not be found, attempting to install..."
        # Add yq installation command for Linux/macOS
        # For example, using sudo apt-get install yq or brew install yq
        # This part needs to be adjusted based on the target system and package manager
        if is_macos; then
            log_info "Detected macOS, attempting to install yq via Homebrew..."
            brew install yq || log_error "Failed to install yq with Homebrew."
        elif is_linux; then
            log_info "Detected Linux, attempting to install yq via apt-get..."
            sudo apt-get update && sudo apt-get install -y yq || log_error "Failed to install yq with apt-get."
        else
            log_error "Unsupported OS for yq installation. Please install yq manually."
            return 1 # Indicate failure
        fi
    else
        log_info "yq is already installed."
    fi
}

# Interactive prompt function
ask_user_confirm() {
    local prompt_message="$1"
    # Default to No if not interactive, or if user just presses Enter
    local default_response="n"
    local response

    if ! is_feature_enabled "interactivePrompts"; then
        log_info "Interactive prompts disabled. Defaulting to 'yes' for prompt: \"$prompt_message\""
        # For non-interactive, we usually assume 'yes' to proceed with automated installs.
        # This can be made configurable per-prompt if needed via another param.
        return 0 # Assume Yes
    fi

    # Loop until a clear y/n or empty (for default) is given
    while true; do
        read -r -p "$prompt_message [y/N]: " response
        response=$(echo "$response" | tr '[:upper:]' '[:lower:]') # Convert to lowercase

        if [[ -z "$response" ]]; then # Empty response, use default
            response="$default_response"
        fi

        if [[ "$response" == "y" ]]; then
            return 0 # True
        elif [[ "$response" == "n" ]]; then
            return 1 # False
        else
            log_warn "Invalid input. Please enter 'y' for yes or 'n' for no."
            # Loop again
        fi
    done
}


# Installation functions
install_git_bash() {
    # Git is fundamental, usually non-interactive, but shown for pattern
    if ! command -v git &> /dev/null; then
        if ask_user_confirm "Git is not installed. Install Git?"; then
            log_info "Attempting to install Git..."
            if is_macos; then
                if command -v brew &> /dev/null; then
                    brew install git || log_error "Failed to install Git with Homebrew."
                else
                    log_error "Homebrew not found. Cannot install Git."
                fi
            elif is_linux; then
                sudo apt-get update && sudo apt-get install -y git || log_error "Failed to install Git with apt-get."
            else
                log_warn "Git installation not configured for this OS. Please install Git manually."
            fi
        else
            log_info "Skipping Git installation based on user input."
        fi
    else
        log_info "Git is already installed."
    fi
}

install_brave_bash() {
    # This is a simplified check. Real check might involve 'dpkg -s brave-browser' or 'brew list brave-browser'
    if ! command -v brave-browser &> /dev/null && ! command -v brave &> /dev/null; then # 'brave' for some linux installs
        if ask_user_confirm "Brave Browser is not installed. Install Brave Browser?"; then
            log_info "Attempting to install Brave Browser..."
            if is_macos; then
                if command -v brew &> /dev/null; then
                    brew install brave-browser || log_error "Failed to install Brave Browser with Homebrew."
                else
                    log_error "Homebrew not found. Cannot install Brave Browser."
                fi
            elif is_linux; then
                log_warn "Brave Browser installation on Linux requires manual steps or a more complex script section. See Brave website."
                log_info "Placeholder: sudo apt-get update && sudo apt-get install -y brave-browser (this might not be the correct package name or method)"
            else
                log_warn "Brave Browser installation not configured for this OS. Please install Brave manually."
            fi
        else
            log_info "Skipping Brave Browser installation based on user input."
        fi
    else
        log_info "Brave Browser is already installed or a 'brave' command exists."
    fi
}

install_oh_my_posh_bash() {
    # Oh My Posh recommends installation via their script for latest version
    if ! command -v oh-my-posh &> /dev/null; then
        if ask_user_confirm "Oh My Posh is not installed. Install Oh My Posh?"; then
            log_info "Attempting to install Oh My Posh..."
            if is_macos; then
                 if command -v brew &> /dev/null; then
                    brew install oh-my-posh || log_error "Failed to install Oh My Posh with Homebrew."
                else
                    log_warn "Homebrew not found. Attempting Oh My Posh script install."
                    curl -s https://ohmyposh.dev/install.sh | bash -s || log_error "Failed to install Oh My Posh using script."
                fi
            elif is_linux; then
                curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin || log_error "Failed to install Oh My Posh using script."
                if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
                     log_warn "$HOME/.local/bin is not in your PATH. Add it to use oh-my-posh, or ensure it's added by your shell profile."
                fi
            else
                log_warn "Oh My Posh installation not configured for this OS (non-macOS/Linux). Please install manually."
            fi
        else
            log_info "Skipping Oh My Posh installation based on user input."
        fi
    else
        log_info "Oh My Posh is already installed."
            if command -v brew &> /dev/null; then
                brew install git || log_error "Failed to install Git with Homebrew."
            else
                log_error "Homebrew not found. Cannot install Git."
            fi
        elif is_linux; then
            sudo apt-get update && sudo apt-get install -y git || log_error "Failed to install Git with apt-get."
        else
            log_warn "Git installation not configured for this OS. Please install Git manually."
        fi
    else
        log_info "Git is already installed."
    fi
}

install_brave_bash() {
    # This is a simplified check. Real check might involve 'dpkg -s brave-browser' or 'brew list brave-browser'
    if ! command -v brave-browser &> /dev/null && ! command -v brave &> /dev/null; then # 'brave' for some linux installs
        log_info "Attempting to install Brave Browser..."
        if is_macos; then
            if command -v brew &> /dev/null; then
                brew install brave-browser || log_error "Failed to install Brave Browser with Homebrew."
            else
                log_error "Homebrew not found. Cannot install Brave Browser."
            fi
        elif is_linux; then
            # Brave installation on Linux is more involved (repo and key setup)
            # For now, just a placeholder message.
            # Example:
            # sudo apt install apt-transport-https curl
            # sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
            # echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list
            # sudo apt update
            # sudo apt install brave-browser
            log_warn "Brave Browser installation on Linux requires manual steps or a more complex script section. See Brave website."
            log_info "Placeholder: sudo apt-get update && sudo apt-get install -y brave-browser (this might not be the correct package name or method)"
        else
            log_warn "Brave Browser installation not configured for this OS. Please install Brave manually."
        fi
    else
        log_info "Brave Browser is already installed or a 'brave' command exists."
    fi
}

install_oh_my_posh_bash() {
    # Oh My Posh recommends installation via their script for latest version
    # curl -s https://ohmyposh.dev/install.sh | bash -s
    if ! command -v oh-my-posh &> /dev/null; then
        log_info "Attempting to install Oh My Posh..."
        if is_macos; then
             if command -v brew &> /dev/null; then
                brew install oh-my-posh || log_error "Failed to install Oh My Posh with Homebrew."
            else
                log_warn "Homebrew not found. Attempting Oh My Posh script install."
                curl -s https://ohmyposh.dev/install.sh | bash -s || log_error "Failed to install Oh My Posh using script."
            fi
        elif is_linux; then
            # On Linux, script install is common. Ensure /usr/local/bin is in PATH for the user.
            curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin || log_error "Failed to install Oh My Posh using script."
            # User might need to add ~/.local/bin to PATH if not already present
            if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
                 log_warn "$HOME/.local/bin is not in your PATH. Add it to use oh-my-posh, or ensure it's added by your shell profile."
            fi
        else
            log_warn "Oh My Posh installation not configured for this OS (non-macOS/Linux). Please install manually."
        fi
    else
        log_info "Oh My Posh is already installed."
    fi
}
# End Installation functions

# Post-install hooks execution
run_post_install_hooks_bash() {
    log_info "Checking for post-install hooks..."
    if ! is_feature_enabled "post_install_hooks.enabled"; then
        log_info "Post-install hooks are disabled globally. Skipping."
        return
    fi

    local hooks_count=$(get_config_value ".post_install_hooks.scripts | length")
    if [[ -z "$hooks_count" || "$hooks_count" -eq 0 ]]; then
        log_info "No post-install hooks defined in config.yaml."
        return
    fi

    log_info "Found $hooks_count post-install hook(s) defined. Processing..."
    local current_os=$(get_os_type)

    for i in $(seq 0 $(($hooks_count - 1))); do
        local hook_run_on_list=$(get_config_value ".post_install_hooks.scripts[$i].run_on")
        local hook_script=$(get_config_value ".post_install_hooks.scripts[$i].script")
        local hook_command=$(get_config_value ".post_install_hooks.scripts[$i].command")
        local hook_description=$(get_config_value ".post_install_hooks.scripts[$i].description")

        # Check if current_os is in hook_run_on_list (e.g., "[linux, macos]")
        local run_this_hook=false
        if [[ "$hook_run_on_list" == *"\"$current_os\""* || "$hook_run_on_list" == *"$current_os"* ]]; then # yq outputs strings with quotes
             # For simple list like [linux, macos], yq gives "linux, macos"
             # For list like run_on: - linux - macos, yq gives "- linux\n- macos"
             # A more robust yq query might be needed if format is inconsistent
             # This basic check works for simple comma-separated or space-separated strings from yq output of an array
            if echo "$hook_run_on_list" | grep -q "$current_os"; then
                 run_this_hook=true
            fi
        fi

        # Simplified check for direct match if yq outputs clean list items (depends on yq version and input YAML)
        # This is more robust if yq eval '.post_install_hooks.scripts[0].run_on[]' gives one item per line
        # For now, using the grep approach on the string representation of the array.
        # A truly robust way is to use yq to filter:
        # yq eval ".post_install_hooks.scripts[$i].run_on[] | select(. == \"$current_os\")" $CONFIG_FILE
        # If this outputs $current_os, then it's a match.

        if $run_this_hook; then
            log_info "Running post-install hook ($((i+1))/$hooks_count): $hook_description"
            if [[ "$hook_script" != "null" && -n "$hook_script" ]]; then
                hook_script_path="$DOTFILES_DIR/$hook_script" # Assuming relative to dotfiles dir
                if [[ -f "$hook_script_path" ]]; then
                    if [[ -x "$hook_script_path" ]]; then
                        log_info "Executing script: $hook_script_path"
                        (cd "$DOTFILES_DIR" && "$hook_script_path") # Execute in context of dotfiles dir
                        if [[ $? -eq 0 ]]; then
                            log_info "Script $hook_script_path executed successfully."
                        else
                            log_error "Script $hook_script_path failed with error code $?."
                        fi
                    else
                        log_error "Script $hook_script_path is not executable. Please use chmod +x."
                    fi
                else
                    log_error "Script $hook_script_path not found."
                fi
            elif [[ "$hook_command" != "null" && -n "$hook_command" ]]; then
                log_info "Executing command: $hook_command"
                eval "$hook_command"
                if [[ $? -eq 0 ]]; then
                    log_info "Command executed successfully: $hook_command"
                else
                    log_error "Command failed with error code $?: $hook_command"
                fi
            else
                log_warn "Hook ($((i+1))/$hooks_count) for $current_os has no valid script or command."
            fi
        else
            log_info "Skipping hook ($((i+1))/$hooks_count): '$hook_description' as it's not targeted for OS '$current_os' (run_on: $hook_run_on_list)."
        fi
        echo # Add a newline for better log readability between hooks
    done
    log_info "Finished processing post-install hooks."
}


reloadProfile() {
    log_info "Reloading: ${SHELL}."
    log_info "Loading user profile: ~/.zshrc" # This implies zsh, might need OS specific profiles in future
    echo
    exec ${SHELL} -l
}

main() {
    log_info "Running on OS: $(get_os_type)"
    install_yq || exit 1 # Exit if yq installation fails and is needed

    # Core software installations
    if is_feature_enabled "installCoreSoftware"; then
        log_info "Feature 'installCoreSoftware' is enabled. Proceeding with core software installations."
        install_git_bash
        install_brave_bash
    else
        log_info "Feature 'installCoreSoftware' is disabled. Skipping core software installations."
    fi

    log_info "Starting chezmoi operations..."
    if ! chezmoi status > /dev/null 2>&1; then
        log_info "Initializing chezmoi..."
        chezmoi init || log_error "chezmoi init failed"
    else
        log_info "chezmoi already initialized."
    fi

    log_info "Adding dotfiles to chezmoi source state..."
    # These are idempotent, chezmoi handles existing files gracefully
    chezmoi add ~/.zshrc
    chezmoi add ~/.zlogin
    chezmoi add ~/.aliases
    chezmoi add ~/.exports
    chezmoi add ~/.functions
    chezmoi add ~/.gitconfig # This will be re-added if content changed by git commands below
    chezmoi add ~/.gvimrc
    chezmoi add ~/.hyper.js
    chezmoi add ~/.tmux.conf
    chezmoi add ~/.vimrc
    chezmoi add ~/brew.sh

    log_info "Configuring git global settings..."
    git_name=$(get_config_value '.tools.git.name')
    git_email=$(get_config_value '.tools.git.email')
    current_git_name=$(git config --global user.name || echo "")
    current_git_email=$(git config --global user.email || echo "")

    if [[ "$current_git_name" != "$git_name" ]]; then
        log_info "Setting git global user.name to '$git_name'..."
        git config --global user.name "$git_name" || log_error "Failed to set git user.name"
    else
        log_info "git global user.name is already set to '$git_name'."
    fi

    if [[ "$current_git_email" != "$git_email" ]]; then
        log_info "Setting git global user.email to '$git_email'..."
        git config --global user.email "$git_email" || log_error "Failed to set git user.email"
    else
        log_info "git global user.email is already set to '$git_email'."
    fi

    # Re-add .gitconfig to chezmoi if it was changed by the above commands
    # This ensures chezmoi tracks the version set by this script from config.yaml
    log_info "Ensuring .gitconfig in chezmoi source state is up-to-date..."
    chezmoi add ~/.gitconfig


    log_info "Applying dotfiles with chezmoi..."
    chezmoi apply || log_error "chezmoi apply failed"

    ensureFolders

    # Feature flag controlled sections
    if is_feature_enabled "withOhMyPosh"; then
        install_oh_my_posh_bash
    else
        log_info "Skipping Oh My Posh installation (feature flag 'withOhMyPosh' is false)."
    fi

    if is_feature_enabled "installDevelopmentTools"; then
        log_info "Attempting to install development tools (feature flag 'installDevelopmentTools' is true)..."
        # Placeholder for other development tools installation logic
        # e.g. install_docker_bash, install_vscode_bash etc.
        log_info "Further development tools installation logic would run here."
    else
        log_info "Skipping development tools installation (feature flag 'installDevelopmentTools' is false)."
    fi

    if is_feature_enabled "setupGitAliases"; then
        log_info "Attempting to setup Git aliases (feature flag 'setupGitAliases' is true)..."
        # Placeholder for Git aliases setup logic
        # This might involve `chezmoi add` for an aliases file, or direct `git config` commands
        log_info "Git aliases setup logic would run here."
    else
        log_info "Skipping Git aliases setup (feature flag 'setupGitAliases' is false)."
    fi

    # Run post-install hooks before reloading profile
    run_post_install_hooks_bash

    reloadProfile
}

main
