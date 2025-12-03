# dotfiles doctor

Run health checks on your dotfiles setup.

## Usage

```bash
dotfiles doctor [OPTIONS]
```

## Options

| Option | Description |
|--------|-------------|
| `--quick` | Skip slow checks (disk space, outdated packages) |
| `--fix` | Attempt to automatically fix issues |
| `--help` | Show help message |

## Examples

```bash
# Run all health checks
dotfiles doctor

# Quick check (faster)
dotfiles doctor --quick

# Auto-fix issues
dotfiles doctor --fix
```

## What It Checks

### Core Tools
- **chezmoi** - Dotfiles manager installed
- **git** - Version control installed
- **homebrew** - Package manager installed (macOS)
- **zsh** - Shell installed and set as default
- **oh-my-zsh** - Zsh framework installed

### 1Password CLI
- **op** - 1Password CLI installed
- **authentication** - Signed in to 1Password

### SSH Keys
- **id_ed25519** or **id_rsa** - SSH key exists
- **config** - SSH config file exists
- **1Password agent** - 1Password SSH agent configured
- **GitHub connection** - SSH authentication works

### XDG Directories
- `XDG_CONFIG_HOME` (~/.config)
- `XDG_DATA_HOME` (~/.local/share)
- `XDG_CACHE_HOME` (~/.cache)
- `XDG_STATE_HOME` (~/.local/state)
- `XDG_BIN_HOME` (~/.local/bin)

### Chezmoi State
- **source directory** - ~/.local/share/chezmoi exists
- **pending changes** - No uncommitted dotfile changes
- **config** - ~/.config/chezmoi/chezmoi.toml exists

### Shell Configuration
- **zshrc** - Main shell config exists
- **aliases** - Aliases file exists
- **exports** - Environment variables file exists
- **functions** - Functions file exists
- **plugins** - Zsh plugins installed (autosuggestions, syntax-highlighting, nvm)

### Git Configuration
- **user.name** - Git name configured
- **user.email** - Git email configured
- **core.editor** - Git editor configured
- **GPG signing** - Commit signing configured (optional)

### Symlink Health
- Checks ~/.config, ~/.local/bin, ~/.local/share for broken symlinks

### Disk Space (skipped with --quick)
- Warns if disk usage > 80%
- Shows cache directory sizes

### Homebrew Packages (skipped with --quick)
- **outdated packages** - Packages needing updates
- **Brewfile sync** - All Brewfile packages installed

### Modern CLI Tools
- lsd (modern ls)
- bat (modern cat)
- fd (modern find)
- rg (ripgrep)
- fzf (fuzzy finder)
- delta (git diff)
- lazygit (git TUI)
- tldr (man pages)

### Development Tools
- Node.js
- Go
- Python
- Ruby
- .NET SDK

### Scheduled Tasks (macOS)
- **brew bundle cron** - Weekly Homebrew update job
- **backup cron** - Weekly backup job

## Output

The doctor uses icons to indicate status:

| Icon | Meaning |
|------|---------|
| ✓ | Check passed |
| ! | Warning (non-critical) |
| ✗ | Check failed (critical) |
| → | Information |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All checks passed (warnings OK) |
| 1 | One or more checks failed |

## Auto-Fix (--fix)

With `--fix`, the doctor will attempt to:
- Create missing XDG directories
- Remove broken symlinks
- Install missing Brewfile packages

## Related Commands

- [dotfiles apply](apply.md) - Apply pending changes
- [dotfiles update](update.md) - Update dotfiles
- [dotfiles cron](cron.md) - Manage scheduled tasks
