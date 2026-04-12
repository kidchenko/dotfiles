# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Cross-platform dotfiles (macOS, Linux & Windows) managed with [Chezmoi](https://chezmoi.io/), following XDG Base Directory conventions.

## Common Commands

```bash
# Bootstrap on new machine (essential tools only, ~15-20 min)
bash tools/bootstrap.sh

# Complete setup after bootstrap (~30-40 min)
dotfiles setup

# Pull and apply latest changes
dotfiles update

# Show pending changes (chezmoi diff + git status)
dotfiles status

# Run health checks
dotfiles doctor

# Manage packages
dotfiles packages              # Install system packages
dotfiles packages outdated     # Check for updates
dotfiles packages cleanup      # Remove unlisted
dotfiles packages global       # Install npm/pip/dotnet tools
dotfiles packages extensions   # Install VS Code + browser extensions
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

`tools/bootstrap.sh` runs: Homebrew install → Chezmoi install → Apply dotfiles → Essential packages (Brewfile.essential) → Oh My Zsh → Zsh plugins → Cron setup

After bootstrap, run `dotfiles setup` for complete installation (packages, extensions, ssh, defaults).

### Global Tools Config

Edit `~/.config/dotfiles/config.yaml` to manage npm/pip/dotnet global tools, then run `dotfiles packages global`.

### Extensions

Edit extension config files, then run `dotfiles packages extensions`:

- `~/.config/dotfiles/vscode-extensions.txt` - VS Code extension IDs (one per line)
- `~/.config/dotfiles/brave-extensions.txt` - Brave extension IDs (one per line)

### Windows Support

- PowerShell profile at `~/Documents/PowerShell/` sources modular config from `~/.config/powershell/`
- Windows bootstrap: `tools/os_installers/setup.ps1`
- Chocolatey packages: `tools/os_installers/choco.ps1`
