# Repository Structure

## Overview

```
dotfiles/
├── home/                        # Chezmoi-managed dotfiles
│   ├── dot_config/              # XDG_CONFIG_HOME (~/.config)
│   │   ├── zsh/                 # Zsh configuration
│   │   │   ├── aliases.sh       # Shell aliases
│   │   │   ├── exports.sh       # Environment variables
│   │   │   ├── functions.sh     # Shell functions
│   │   │   └── completions/     # Custom completions
│   │   ├── nvim/                # Neovim configuration
│   │   ├── git/                 # Git configuration
│   │   └── tmux/                # Tmux configuration
│   ├── dot_zshrc.tmpl           # Main shell config → ~/.zshrc
│   ├── dot_gitconfig.tmpl       # Git config → ~/.gitconfig
│   ├── private_dot_ssh/         # SSH configuration
│   │   └── config.tmpl          # SSH client config
│   ├── .chezmoi.toml.tmpl       # Chezmoi config template
│   └── .chezmoiignore           # Files to ignore conditionally
│
├── tools/                       # Management scripts
│   ├── dotfiles                 # CLI tool (main entry point)
│   ├── bootstrap.sh             # One-line installer
│   ├── doctor.sh                # Health checks
│   ├── destroy.sh               # Uninstaller
│   ├── update.sh                # Update checker
│   ├── setup-ssh-keys.sh        # SSH key generation
│   ├── install-global-tools.sh  # npm/pip/dotnet installer
│   ├── install-vscode-extensions.sh  # VS Code extensions
│   ├── install-brave-extensions.sh   # Brave browser extensions
│   └── os_setup/
│       └── macos-config.sh      # macOS defaults
│
├── cron/                        # Scheduled tasks
│   ├── setup-cron.sh            # Cron installer
│   ├── update.sh                # Homebrew update job
│   └── backup.sh                # Backup job
│
├── scripts/                     # User scripts
│   └── backup/
│       └── backup-projects.sh   # Project backup script
│
├── Brewfile                     # Homebrew packages
├── CLAUDE.md                    # AI assistant instructions
└── README.md                    # Main documentation
```

## File Naming Conventions

Chezmoi uses prefixes to determine how files are processed:

| Prefix | Effect | Example |
|--------|--------|---------|
| `dot_` | Replaced with `.` | `dot_zshrc` → `.zshrc` |
| `private_` | Permissions set to 0600 | `private_dot_ssh/` |
| `executable_` | Permissions include +x | `executable_script.sh` |
| `empty_` | Create empty file | `empty_dot_placeholder` |
| `modify_` | Run script to modify existing | `modify_dot_config.sh` |
| `run_` | Run script during apply | `run_setup.sh` |

| Suffix | Effect | Example |
|--------|--------|---------|
| `.tmpl` | Process as Go template | `dot_gitconfig.tmpl` |

## XDG Base Directory

All configurations follow the [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/latest/):

| Variable | Default | Purpose |
|----------|---------|---------|
| `XDG_CONFIG_HOME` | `~/.config` | User configuration files |
| `XDG_DATA_HOME` | `~/.local/share` | User data files |
| `XDG_CACHE_HOME` | `~/.cache` | Non-essential cached data |
| `XDG_STATE_HOME` | `~/.local/state` | State data (logs, history) |
| `XDG_BIN_HOME` | `~/.local/bin` | User executables |

### Chezmoi Paths

| Path | Purpose |
|------|---------|
| `~/.local/share/chezmoi` | Dotfiles source repository |
| `~/.config/chezmoi/chezmoi.toml` | Chezmoi configuration |
| `~/.cache/chezmoi` | Chezmoi cache |

### Dotfiles Data Paths

| Path | Purpose |
|------|---------|
| `~/.config/dotfiles/config.yaml` | Dotfiles configuration |
| `~/.config/dotfiles/vscode-extensions.txt` | VS Code extensions list |
| `~/.config/dotfiles/brave-extensions.txt` | Brave extensions list |
| `~/.local/share/dotfiles/backups/` | Project backups |
| `~/.local/log/` | Cron job logs |

## Key Files Explained

### `tools/dotfiles`

The main CLI tool. Provides commands like `doctor`, `apply`, `update`, `ssh`, etc.

### `tools/bootstrap.sh`

Fast bootstrap (~15-20 min) that installs essentials:
1. Installs Homebrew
2. Installs Chezmoi
3. Applies dotfiles
4. Installs essential packages (Brewfile.essential)
5. Installs Oh My Zsh + plugins
6. Links the `dotfiles` CLI

After bootstrap, run `dotfiles setup` for complete setup (SSH, full software, extensions, defaults).

### `tools/doctor.sh`

Health check script that verifies:
- Core tools installation
- 1Password CLI status
- SSH key presence
- XDG directories
- Chezmoi state
- Shell configuration
- Git configuration
- Symlink integrity
- Disk space
- Homebrew packages
- Modern CLI tools
- Development tools
- Scheduled tasks

### `tools/destroy.sh`

Uninstaller with three levels:
- **Default**: Remove managed dotfiles only
- **`--all`**: Remove dotfiles + chezmoi state + brew packages
- **`--deep`**: Factory reset (removes all dev tools, caches)

### `home/.chezmoi.toml.tmpl`

Template for Chezmoi config. Prompts for user data (name, email, editor).

### `home/.chezmoiignore`

Ignores files that shouldn't be managed by Chezmoi (SSH keys are managed via `dotfiles ssh`).

## Uninstalling

### Remove Dotfiles Only

```bash
dotfiles destroy
```

Removes all chezmoi-managed files from your home directory.

### Full Cleanup

```bash
dotfiles destroy --all
```

Also removes:
- Chezmoi source directory
- Chezmoi config and cache
- Zsh data and cache
- Homebrew packages from Brewfile

### Factory Reset

```bash
dotfiles destroy --deep
```

Additionally removes:
- Oh My Zsh
- Shell histories (zsh, bash, python, node, etc.)
- Package manager caches (npm, yarn, pip, cargo, etc.)
- Development tool data (.dotnet, .cargo, .rustup, etc.)
- All XDG directories

**Warning:** This is destructive and will require reinstalling development tools.

## Adding to This Structure

### New Dotfile

```bash
# Add existing file
chezmoi add ~/.my-config

# Add as template
chezmoi add --template ~/.my-config
```

### New Script

1. Create script in `tools/`
2. Add command to `tools/dotfiles`
3. Document in README

### New Cron Job

1. Create script in `cron/`
2. Add entry to `CRON_JOBS` array in `cron/setup-cron.sh`
3. Run `dotfiles cron setup`
