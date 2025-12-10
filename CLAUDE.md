# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Cross-platform dotfiles (macOS, Linux & Windows) managed with [Chezmoi](https://chezmoi.io/), following XDG Base Directory conventions.

## Common Commands

```bash
# Apply dotfile changes
chezmoi apply

# Pull and apply from remote
chezmoi update

# Preview pending changes
chezmoi diff

# Verify chezmoi setup
chezmoi doctor

# Install Homebrew packages (macOS)
brew bundle install

# Install global tools (npm/pip/dotnet)
bash tools/install-global-tools.sh

# Install VS Code extensions
bash tools/install-vscode-extensions.sh

# Full bootstrap on new machine
bash tools/bootstrap.sh
```

## Architecture

### Chezmoi Template System
- Source files live in `home/` directory with Chezmoi naming conventions
- `dot_` prefix → `.` (e.g., `dot_gitconfig.tmpl` → `~/.gitconfig`)
- `.tmpl` suffix indicates Go template processing
- Machine-specific config via `.chezmoidata.yaml` in repo root (defines variables like `email`, `name`, `is_work_machine`)
- Chezmoi stores source at `~/.local/share/chezmoi`, config at `~/.config/chezmoi/chezmoi.toml`

### XDG Directory Structure
All configs follow XDG conventions:
- `~/.config` (XDG_CONFIG_HOME) - App configurations
- `~/.local/share` (XDG_DATA_HOME) - App data, Zsh history, NVM, SDKMAN
- `~/.cache` (XDG_CACHE_HOME) - Cache files
- `~/.local/bin` (XDG_BIN_HOME) - User binaries

### Key Directories
- `home/` - Chezmoi-managed dotfile templates
- `home/dot_config/` - XDG config files (zsh, nvim, tmux, git, etc.)
- `tools/` - Bootstrap and management scripts
- `tools/os_installers/` - OS-specific package installers (brew.sh, apt.sh, choco.ps1)
- `cron/` - Scheduled tasks (weekly brew bundle updates on Mondays at 9am)
- `Brewfile` - Homebrew package manifest

### Bootstrap Flow
`tools/bootstrap.sh` runs: Homebrew install → Chezmoi install → Apply dotfiles → Brew bundle → Oh My Zsh → Zsh plugins → Cron setup

### Global Tools Config
Edit `~/.config/dotfiles/config.yaml` to manage npm/pip/dotnet global tools, then run `tools/install-global-tools.sh`.

### VS Code Extensions
Edit `~/.config/dotfiles/vscode-extensions.txt` (one extension ID per line), then run `tools/install-vscode-extensions.sh`.

### Brave Extensions
Edit `~/.config/dotfiles/brave-extensions.txt` (one extension ID per line), then run `tools/install-brave-extensions.sh`.

### Windows Support
- PowerShell profile at `~/Documents/PowerShell/` sources modular config from `~/.config/powershell/`
- Windows bootstrap: `tools/os_installers/setup.ps1`
- Chocolatey packages: `tools/os_installers/choco.ps1`
