# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal dotfiles repository managed with [Chezmoi](https://chezmoi.io/), designed for cross-platform (macOS and Linux) configuration management. The project follows the XDG Base Directory Specification for clean home directory organization.

**Key Technologies:**
- **Chezmoi**: Dotfile templating and deployment system
- **XDG Compliance**: Configurations in `~/.config`, data in `~/.local/share`, cache in `~/.cache`
- **Oh My Zsh**: Zsh framework with custom plugins and theme (avit)
- **Automated Tooling**: Global tool installation (npm, pip, dotnet) via YAML config

## Repository Structure

```
dotfiles/
├── home/                    # Chezmoi source templates (what gets deployed)
│   ├── .config/            # XDG config templates (zsh, nvim, tmux, git, etc.)
│   │   ├── zsh/            # Zsh configs (.zshrc, aliases, functions, exports)
│   │   ├── nvim/           # Neovim configuration
│   │   ├── tmux/           # Tmux configuration
│   │   ├── git/            # Git aliases and configs
│   │   ├── dotfiles/       # config.yaml.tmpl, vscode-extensions.txt.tmpl
│   │   └── chezmoi/        # chezmoi.toml.tmpl
│   └── dot_*.tmpl          # Files for home directory (e.g., .profile, .gitconfig)
├── tools/                  # Bootstrap and management scripts
│   ├── bootstrap.sh        # Main entry point for setup
│   ├── xdg_setup.sh        # XDG environment variables setup
│   ├── run_once_install-chezmoi.sh
│   ├── install_global_tools.sh      # Installs npm/pip/dotnet packages
│   ├── install_vscode_extensions.sh
│   ├── update.sh
│   ├── os_installers/      # OS-specific package managers (apt.sh, brew.sh, choco.ps1)
│   └── os_setup/           # OS-specific configs (macos_config.sh)
├── scripts/                # User utilities and custom hooks
│   ├── backup/             # Backup utilities
│   └── custom/             # Custom hook scripts for post-install
├── tests/                  # Automated tests (Bats for Bash, Pester for PowerShell)
│   ├── bash/
│   └── powershell/
├── tools/config.yaml       # Central configuration (git user, feature flags, hooks)
└── .github/workflows/      # CI/CD for linting and testing
```

## Common Commands

### Bootstrap/Installation

```bash
# Initial setup (from URL)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/kidchenko/dotfiles/v2/tools/bootstrap.sh)"

# Or from local clone
git clone https://github.com/kidchenko/dotfiles.git ~/dotfiles_source
cd ~/dotfiles_source
bash tools/bootstrap.sh

# Bootstrap with options
bash tools/bootstrap.sh --verbose --dry-run
bash tools/bootstrap.sh --force-chezmoi-init
bash tools/bootstrap.sh --repo https://github.com/yourfork/dotfiles.git
```

### Chezmoi Operations

```bash
# Apply latest changes from source
chezmoi apply

# Update from remote and apply
chezmoi update

# See what would change
chezmoi diff

# Edit a managed file
chezmoi edit ~/.zshrc

# Check Chezmoi setup
chezmoi doctor
```

### Tool Management

```bash
# Install/update global tools (npm, pip, dotnet)
bash tools/install_global_tools.sh --verbose

# Install VS Code extensions
bash tools/install_vscode_extensions.sh

# Dry run mode available for both
bash tools/install_global_tools.sh --dry-run
```

### Testing

```bash
# Run tests (from tests/ directory)
cd tests/bash && bats *.bats
cd tests/powershell && pwsh -Command "Invoke-Pester"
```

## Architecture & Key Concepts

### Chezmoi Templating System

All files in `home/` are Chezmoi templates:
- `.tmpl` extension indicates Go templating
- `dot_` prefix becomes `.` in target (e.g., `dot_gitconfig.tmpl` → `~/.gitconfig`)
- Templates can use data from `.chezmoidata.yaml` (if exists)

**Template Variables:**
```gotemplate
{{ .email }}              # From .chezmoidata.yaml
{{ .is_work_machine }}    # Boolean for conditional configs
{{ .chezmoi.hostname }}   # Built-in Chezmoi variables
{{ .chezmoi.os }}         # OS detection (darwin, linux, etc.)
```

### XDG Base Directory Compliance

**Environment Variables Set:**
- `XDG_CONFIG_HOME`: `~/.config` (configurations)
- `XDG_DATA_HOME`: `~/.local/share` (application data)
- `XDG_CACHE_HOME`: `~/.cache` (cache files)
- `XDG_STATE_HOME`: `~/.local/state` (state files like history)
- `XDG_BIN_HOME`: `~/.local/bin` (user binaries)

**Zsh XDG Locations:**
- `ZDOTDIR`: `~/.config/zsh`
- `HISTFILE`: `~/.local/state/zsh/history` (or `~/.local/share/zsh/history`)

### Global Tools Configuration

Edit `~/.config/dotfiles/config.yaml` (generated from `home/.config/dotfiles/config.yaml.tmpl`):

```yaml
global_tools:
  npm:
    - http-server
    - eslint
  pip:
    - black
    - flake8
  dotnet:
    - dotnet-ef
```

### Post-Install Hooks

Hooks in `tools/config.yaml` execute custom scripts after installation:

```yaml
post_install_hooks:
  enabled: true
  scripts:
    - run_on: [macos, linux]
      script: "./scripts/custom/my_bash_hook.sh"
      description: "Custom setup for Unix systems"
    - run_on: [windows]
      script: "./scripts/custom/my_powershell_hook.ps1"
```

## Zsh Configuration Details

**Load Order:**
1. `.zshrc` (main config from `home/.config/zsh/.zshrc.tmpl`)
2. `exports.sh` (environment variables)
3. `aliases.sh` (command aliases)
4. `functions.sh` (custom functions)
5. `.zlogin` (login shell specific)

**Oh My Zsh Plugins Used:**
- git, zsh-autosuggestions, zsh-nvm, node, npm, kubectl, dotnet, zsh-syntax-highlighting

**Theme:** avit

## Bootstrap Script Workflow

When `tools/bootstrap.sh` runs:

1. **Dependency Check**: Ensures git, curl/wget are installed
2. **XDG Setup**: Sources `xdg_setup.sh` to set XDG environment variables
3. **Chezmoi Install**: Runs `run_once_install-chezmoi.sh` if needed
4. **Chezmoi Init/Apply**:
   - First run: `chezmoi init --apply <repo_url>`
   - Subsequent runs: `chezmoi apply`
5. **yq Installation**: Attempts to install yq (YAML parser) if missing
6. **Global Tools**: Runs `install_global_tools.sh`
7. **VS Code Extensions**: Runs `install_vscode_extensions.sh`

## File Naming Conventions

**Chezmoi Prefixes:**
- `dot_` → `.` (dotfiles)
- `private_` → file with 0600 permissions
- `executable_` → file with execute permissions
- `run_once_` → script that runs once (tracked by Chezmoi state)
- `run_onchange_` → script that runs when it changes
- `.tmpl` → Go template processed by Chezmoi

## Important Paths

- **Chezmoi Source**: `~/.local/share/chezmoi` (this repo cloned by Chezmoi)
- **Chezmoi Config**: `~/.config/chezmoi/chezmoi.toml`
- **Global Tools Config**: `~/.config/dotfiles/config.yaml`
- **VS Code Extensions List**: `~/.config/dotfiles/vscode-extensions.txt`
- **Zsh Config Directory**: `~/.config/zsh`

## Development Notes

- **Idempotency**: All scripts support multiple runs safely
- **Dry-Run Mode**: Most scripts accept `--dry-run` flag
- **Verbose Mode**: Use `--verbose` for detailed output
- **Testing**: Use Bats (Bash) and Pester (PowerShell) in `tests/`
- **CI/CD**: GitHub Actions in `.github/workflows/ci.yml` for automated testing

## Machine-Specific Customization

Create `.chezmoidata.yaml` in repository root:

```yaml
email: "user@example.com"
name: "Your Name"
is_work_machine: false
```

Then use in templates:
```gotemplate
# In home/.config/git/config.tmpl
[user]
  email = {{ .email | default "fallback@example.com" }}
  name = {{ .name | default "Fallback Name" }}

{{ if .is_work_machine }}
# Work-specific configuration
{{ end }}
```

## When Modifying Dotfiles

1. Edit template files in forked repository (in `home/` directory)
2. Commit and push changes
3. Run `chezmoi update` on target machines (pulls + applies)
4. Or run `chezmoi apply` if changes already in local source

## Dependencies

**Required:**
- Git
- curl or wget
- yq (YAML processor) - auto-installed if package manager available

**Optional:**
- npm (for npm global tools)
- pip/pip3 (for Python packages)
- dotnet (for .NET tools)
- VS Code (for extension installation)
- Homebrew (macOS) or apt/dnf/yum (Linux) for package management
