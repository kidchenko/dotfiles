# @kidchenko's Dotfiles

Cross-platform dotfiles (macOS, Linux & Windows) managed with [Chezmoi](https://chezmoi.io/), following [XDG Base Directory](https://specifications.freedesktop.org/basedir-spec/latest/) conventions.

## Quick Start

```bash
# One-line bootstrap on a new machine (~15-20 min)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/kidchenko/dotfiles/v1.0.0/tools/bootstrap.sh)"

# Preview what will be installed (dry-run)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/kidchenko/dotfiles/v1.0.0/tools/bootstrap.sh)" -- --dry-run
```

Bootstrap installs essential dev tools only. After bootstrap, install the full software suite:

```bash
# Install full software suite (~30-40 min)
dotfiles install
```

> **Tip**: Use a tagged release (e.g., `v1.0.0`) for stability. Check [releases](https://github.com/kidchenko/dotfiles/releases) for the latest version.

## What's Included

| Category | Tools |
|----------|-------|
| **Shell** | Zsh + Oh My Zsh, aliases, functions, completions |
| **Git** | Templated config, delta diff viewer, lazygit |
| **Editor** | Neovim, VS Code extensions sync |
| **Terminal** | Tmux, modern CLI tools (lsd, bat, fd, ripgrep, fzf) |
| **Secrets** | 1Password CLI integration for SSH keys |
| **Automation** | Weekly Homebrew updates, scheduled backups |
| **macOS** | System preferences, Dock, Finder optimizations |

## Dotfiles CLI

After installation, use the `dotfiles` command to manage everything:

```bash
dotfiles help              # Show all commands
```

### Core Commands

| Command | Description |
|---------|-------------|
| `dotfiles doctor` | Run health checks on your setup |
| `dotfiles apply` | Apply pending dotfile changes |
| `dotfiles update` | Pull and apply latest changes |
| `dotfiles diff` | Preview pending changes |
| `dotfiles edit` | Open dotfiles in your editor |
| `dotfiles status` | Show git status of dotfiles |

### Package Management

| Command | Description |
|---------|-------------|
| `dotfiles install` | Install full software suite (Brewfile) |
| `dotfiles cleanup` | List packages not in Brewfile |
| `dotfiles extensions` | Install VS Code extensions |

### Maintenance

| Command | Description |
|---------|-------------|
| `dotfiles doctor --quick` | Fast health check (skip slow checks) |
| `dotfiles doctor --fix` | Auto-fix common issues |
| `dotfiles backup` | Create project backup |
| `dotfiles backup list` | List available backups |
| `dotfiles logs` | View cron job logs |
| `dotfiles cron` | List scheduled tasks |
| `dotfiles cron setup` | Setup/update cron jobs |

### System Setup

| Command | Description |
|---------|-------------|
| `dotfiles ssh` | Generate SSH key in 1Password |
| `dotfiles defaults` | Apply macOS system preferences |
| `dotfiles bootstrap` | Full bootstrap (for new machines) |
| `dotfiles destroy` | Remove all dotfiles |

## Secrets Management (1Password)

SSH keys are generated directly in 1Password - the private key never touches disk during generation.

```bash
# First time setup (generate new SSH key)
op signin                    # Sign in to 1Password CLI
dotfiles ssh                 # Generate Ed25519 key in 1Password
                             # Copy public key to GitHub/GitLab

# On a new machine (restore existing key)
op signin                    # Sign in to 1Password CLI
chezmoi apply                # SSH keys restored automatically
```

Keys are stored at `op://development/SSH Key/` and restored via Chezmoi templates.

## Scheduled Tasks

Two cron jobs are set up automatically:

| Schedule | Task | Description |
|----------|------|-------------|
| Monday 9am | `cron/update.sh` | Update Homebrew packages |
| Sunday 2am | `cron/backup.sh` | Backup projects (keeps 7 days) |

Manage with `dotfiles cron` and `dotfiles logs`.

Backups are stored in `~/.local/share/dotfiles/backups/` (XDG-compliant).

## Directory Structure

```
dotfiles/
├── home/                    # Chezmoi-managed dotfiles
│   ├── dot_config/          # ~/.config files (zsh, nvim, git, etc.)
│   ├── dot_zshrc.tmpl       # Main shell config
│   └── private_dot_ssh/     # SSH config templates
├── tools/                   # Management scripts
│   ├── dotfiles             # CLI tool
│   ├── bootstrap.sh         # One-line installer
│   ├── doctor.sh            # Health checks
│   ├── destroy.sh           # Uninstaller
│   ├── setup-ssh-keys.sh    # SSH key generation
│   └── os_setup/            # OS-specific configs
├── cron/                    # Scheduled tasks
├── scripts/                 # User scripts (backup, etc.)
└── Brewfile                 # Homebrew packages
```

## Customization

### Global Tools

Edit `~/.config/dotfiles/config.yaml` to manage npm/pip/dotnet tools:

```yaml
global_tools:
  npm:
    - typescript
    - prettier
  pip:
    - httpie
  dotnet:
    - dotnet-ef
```

Then run the installer:

```bash
bash tools/install-global-tools.sh
```

### VS Code Extensions

Edit `~/.config/dotfiles/vscode-extensions.txt` (one extension ID per line):

```
ms-python.python
esbenp.prettier-vscode
```

Then run:

```bash
dotfiles extensions
```

### macOS Defaults

The `dotfiles defaults` command applies developer-friendly macOS settings:

- Fast keyboard repeat, tap-to-click
- Show hidden files, file extensions
- Auto-hide Dock, disable animations
- Screenshots to ~/Documents/Screenshots
- Hot corners (Lock Screen, Mission Control, Launchpad)

Review settings in `tools/os_setup/macos-config.sh` before running.

## Bootstrap Flow

When you run `bootstrap.sh`, it executes in this order:

1. **Homebrew** - Install package manager (macOS)
2. **Chezmoi** - Install dotfiles manager
3. **Brewfile** - Install all packages (includes 1password-cli)
4. **1Password** - Prompt to sign in for secrets
5. **SSH Keys** - Generate or restore from 1Password
6. **Dotfiles** - Apply all configurations
7. **Oh My Zsh** - Install shell framework
8. **Plugins** - Install zsh-autosuggestions, zsh-syntax-highlighting, zsh-nvm
9. **Cron** - Setup scheduled tasks
10. **CLI** - Install `dotfiles` command

## Uninstalling

```bash
# Remove managed dotfiles only
dotfiles destroy

# Remove dotfiles + chezmoi state + brew packages
dotfiles destroy --all

# Factory reset (removes dev tools, caches, histories)
dotfiles destroy --deep
```

## Documentation

| Guide | Description |
|-------|-------------|
| [Installation](docs/installation.md) | Prerequisites, bootstrap options, troubleshooting |
| [Customization](docs/customization.md) | Fork setup, templating, adding packages |
| [Structure](docs/structure.md) | Repository layout, XDG paths, key files |
| [Commands](docs/commands/README.md) | Full CLI reference (one page per command) |

---

Built with care by [@kidchenko](https://github.com/kidchenko)
