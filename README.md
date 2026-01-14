# @kidchenko's Dotfiles

Cross-platform dotfiles (macOS, Linux & Windows) managed with [Chezmoi](https://chezmoi.io/), following [XDG Base Directory](https://specifications.freedesktop.org/basedir-spec/latest/) conventions.

## Why?

Setting up a new machine takes hours. Configurations drift between machines. Packages get outdated. SSH keys sit on disk. This project solves all of that:

| Problem | Solution |
|---------|----------|
| New machine setup takes hours | Single command, minutes |
| Configuration drift between machines | One repo, templated variations |
| Packages get outdated | Automated weekly updates |
| SSH keys on disk are a security risk | Keys stored in 1Password |
| Dotfiles scattered everywhere | XDG-compliant structure |
| No visibility into system health | `dotfiles doctor` command |
| Backups are forgotten | Automated weekly with retention |

See [Problem Statement](docs/problem-statement.md) for the full rationale.

## Quick Start

```bash
# One-line bootstrap on a new machine
bash -c "$(curl -fsSL https://raw.githubusercontent.com/kidchenko/dotfiles/main/tools/bootstrap.sh)"

# Preview what will be installed (dry-run)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/kidchenko/dotfiles/main/tools/bootstrap.sh)" -- --dry-run
```

Bootstrap installs essential dev tools only. After bootstrap, run the full setup:

```bash
# Complete setup (packages, extensions, ssh, defaults)
dotfiles setup
```

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

### Daily

| Command | Description |
|---------|-------------|
| `dotfiles update` | Pull and apply latest changes |
| `dotfiles doctor` | Run health checks on your setup |
| `dotfiles status` | Show pending changes (chezmoi diff + git status) |

### Packages

| Command | Description |
|---------|-------------|
| `dotfiles packages` | Install system packages (Brewfile) |
| `dotfiles packages cleanup` | Remove unlisted packages |
| `dotfiles packages outdated` | Show packages with updates |
| `dotfiles packages global` | Install global tools (npm/pip/dotnet) |
| `dotfiles packages extensions` | Install VS Code/browser extensions |

### System

| Command | Description |
|---------|-------------|
| `dotfiles ssh` | Setup SSH keys with 1Password |
| `dotfiles defaults` | Apply macOS system preferences |
| `dotfiles cron` | Manage scheduled tasks |
| `dotfiles logs` | View cron job logs |
| `dotfiles backup` | Backup project folders |

### Lifecycle

| Command | Description |
|---------|-------------|
| `dotfiles setup` | Complete post-bootstrap setup |
| `dotfiles bootstrap` | Bootstrap on new machine |
| `dotfiles destroy` | Remove dotfiles and state |

## Secrets Management (1Password)

SSH keys are generated and stored directly in 1Password - the private key never touches disk during generation.

### Setup SSH Keys

```bash
dotfiles ssh                 # Interactive menu for SSH key management
```

Options:
- **restore** - Restore existing key from 1Password to `~/.ssh/`
- **generate** - Generate new Ed25519 key directly in 1Password
- **show** - Display your public key (for adding to GitHub/GitLab)
- **compare** - Compare local key with 1Password version

### How It Works

```
Traditional (Unsafe):
  ssh-keygen → Key on disk → Copy to USB/cloud → Multiple copies, multiple risks

1Password Workflow (Safe):
  op item create → Key in vault → Restored via Chezmoi → Key in memory only
```

Keys are stored at `op://development/SSH Key/` and restored automatically when you run `chezmoi apply`.

## Scheduled Tasks

Six cron jobs are set up automatically:

**Security & Updates**
| Schedule | Task | Description |
|----------|------|-------------|
| Daily 8am | `outdated.sh` | Check for outdated packages |
| Monday 9am | `update.sh` | Update Homebrew packages |
| Sunday 10am | `cleanup.sh` | Cleanup brew cache & temp files |

**Backups & Maintenance**
| Schedule | Task | Description |
|----------|------|-------------|
| Sunday 2am | `backup.sh` | Backup projects (git sync + archive) |
| Saturday 4am | `git-maintenance.sh` | Run git gc on repositories |

**Health Monitoring**
| Schedule | Task | Description |
|----------|------|-------------|
| Daily 7am | `health.sh` | System health check |

Manage with `dotfiles cron` and view logs with `dotfiles logs`.

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
│   ├── backup-projects.sh   # Backup utility
│   ├── setup-ssh-keys.sh    # SSH key generation
│   └── os_setup/            # OS-specific configs
├── cron/                    # Scheduled tasks
└── Brewfile                 # Homebrew packages
```

## Customization

### Packages

Edit `Brewfile` to add/remove Homebrew packages, then run:

```bash
dotfiles packages
```

### Extensions

Edit config files, then run `dotfiles packages extensions`:

| Config File | Description |
|-------------|-------------|
| `~/.config/dotfiles/vscode-extensions.txt` | VS Code extension IDs (one per line) |
| `~/.config/dotfiles/brave-extensions.txt` | Browser extension IDs |

### Global Tools (npm/pip/dotnet)

Edit `~/.config/dotfiles/config.yaml`:

```yaml
global_tools:
  npm: [typescript, prettier]
  pip: [httpie]
  dotnet: [dotnet-ef]
```

Then run: `dotfiles packages global`

### macOS Defaults

The `dotfiles defaults` command applies developer-friendly settings (keyboard, Dock, Finder, screenshots). Review `tools/os_setup/macos-config.sh` before running.

## Bootstrap Flow

When you run `bootstrap.sh`, it executes in this order:

1. **Homebrew** - Install package manager (macOS)
2. **Chezmoi** - Install dotfiles manager
3. **Dotfiles** - Apply all configurations
4. **Essential Packages** - Install from `Brewfile.essential` (git, fzf, ripgrep, bat, Hyper, fonts)
5. **Oh My Zsh** - Install shell framework
6. **Plugins** - Install zsh-autosuggestions, zsh-syntax-highlighting, zsh-nvm
7. **Directories** - Create project folders (~/kidchenko, ~/lambda3, etc.)
8. **CLI** - Install `dotfiles` command

After bootstrap, run `dotfiles setup` for complete installation (full packages, SSH keys, extensions, system defaults, cron jobs).

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
