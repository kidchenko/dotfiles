#!/bin/bash

# tools/xdg-setup.sh
#
# Sets XDG Base Directory Specification environment variables for the current session
# and ensures the base directories exist.
# This script is intended to be sourced by the main bootstrap script to make
# XDG variables available to subsequent scripts in the bootstrap process.

# --- Helper function to print messages ---
_xdg_say() {
    echo "xdg-setup: $1"
}

# --- Define and export XDG variables with fallbacks ---

# XDG_CONFIG_HOME: For user-specific configuration files.
if [ -z "$XDG_CONFIG_HOME" ]; then
  export XDG_CONFIG_HOME="$HOME/.config"
  # _xdg_say "XDG_CONFIG_HOME not set, defaulting to $XDG_CONFIG_HOME"
fi

# XDG_CACHE_HOME: For user-specific non-essential (cached) data.
if [ -z "$XDG_CACHE_HOME" ]; then
  export XDG_CACHE_HOME="$HOME/.cache"
  # _xdg_say "XDG_CACHE_HOME not set, defaulting to $XDG_CACHE_HOME"
fi

# XDG_DATA_HOME: For user-specific data files.
if [ -z "$XDG_DATA_HOME" ]; then
  export XDG_DATA_HOME="$HOME/.local/share"
  # _xdg_say "XDG_DATA_HOME not set, defaulting to $XDG_DATA_HOME"
fi

# XDG_STATE_HOME: For user-specific state files (e.g., logs, history). New addition to spec.
if [ -z "$XDG_STATE_HOME" ]; then
  export XDG_STATE_HOME="$HOME/.local/state"
  # _xdg_say "XDG_STATE_HOME not set, defaulting to $XDG_STATE_HOME"
fi

# XDG_BIN_HOME: For user-specific executables (not official XDG, but common convention like ~/.local/bin)
# This is often added to PATH.
if [ -z "$XDG_BIN_HOME" ]; then
    export XDG_BIN_HOME="$HOME/.local/bin"
    # _xdg_say "XDG_BIN_HOME not set, defaulting to $XDG_BIN_HOME"
fi

# XDG_RUNTIME_DIR: For user-specific non-essential runtime files and other file objects (sockets, pipes, etc.).
# This one has specific requirements (permissions, cleared on boot) and is usually set by the system (e.g., systemd).
# We generally should not set it ourselves unless we know what we're doing.
# if [ -z "$XDG_RUNTIME_DIR" ]; then
#   export XDG_RUNTIME_DIR="/run/user/$(id -u)" # Example, but system should handle this.
#   # mkdir -p "$XDG_RUNTIME_DIR"
#   # chmod 0700 "$XDG_RUNTIME_DIR"
# fi

# --- Ensure XDG base directories exist ---
# Applications should create their own subdirectories within these.
_xdg_say "Ensuring XDG base directories exist..."
mkdir -p \
  "$XDG_CONFIG_HOME" \
  "$XDG_CACHE_HOME" \
  "$XDG_DATA_HOME" \
  "$XDG_STATE_HOME" \
  "$XDG_BIN_HOME"

# --- ZDOTDIR for Zsh ---
# If running in Zsh context and ZDOTDIR is not set, set it for XDG compliance.
# This helps ensure that if the bootstrap script uses zsh -c "...", it knows where configs are.
if [ -n "$ZSH_VERSION" ]; then # Check if the SCRIPT is run by Zsh, not if Zsh is the user's shell
  if [ -z "$ZDOTDIR" ]; then
    export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
    # _xdg_say "ZDOTDIR not set for Zsh script context, defaulting to $ZDOTDIR"
  fi
  mkdir -p "$ZDOTDIR"
fi

_xdg_say "XDG environment variables configured for this session:"
_xdg_say "  XDG_CONFIG_HOME = $XDG_CONFIG_HOME"
_xdg_say "  XDG_CACHE_HOME  = $XDG_CACHE_HOME"
_xdg_say "  XDG_DATA_HOME   = $XDG_DATA_HOME"
_xdg_say "  XDG_STATE_HOME  = $XDG_STATE_HOME"
_xdg_say "  XDG_BIN_HOME    = $XDG_BIN_HOME"
if [ -n "$ZSH_VERSION" ] && [ -n "$ZDOTDIR" ]; then
    _xdg_say "  ZDOTDIR         = $ZDOTDIR (for Zsh context)"
fi

# This script should be sourced, e.g.:
# source ./tools/xdg-setup.sh
# or
# . ./tools/xdg-setup.sh
# So that the exported variables are available in the calling shell.
true # Ensure script exits with success if sourced.
