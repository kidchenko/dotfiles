# Dotfiles CLI Commands

Complete reference for all `dotfiles` commands.

## Quick Reference

```bash
dotfiles help              # Show all commands
```

## Daily

| Command | Description | Documentation |
|---------|-------------|---------------|
| `dotfiles update` | Pull and apply from remote | [update.md](update.md) |
| `dotfiles doctor` | Run health checks | [doctor.md](doctor.md) |
| `dotfiles status` | Show pending changes | [status.md](status.md) |

## Packages

| Command | Description | Documentation |
|---------|-------------|---------------|
| `dotfiles packages` | Manage system packages | [packages.md](packages.md) |
| `dotfiles extensions` | Install extensions | [extensions.md](extensions.md) |

## System

| Command | Description | Documentation |
|---------|-------------|---------------|
| `dotfiles ssh` | Setup SSH keys | [ssh.md](ssh.md) |
| `dotfiles defaults` | Apply macOS settings | [defaults.md](defaults.md) |
| `dotfiles cron` | Manage scheduled tasks | [cron.md](cron.md) |
| `dotfiles logs` | View logs | [logs.md](logs.md) |
| `dotfiles backup` | Backup projects | [backup.md](backup.md) |

## Lifecycle

| Command | Description | Documentation |
|---------|-------------|---------------|
| `dotfiles setup` | Complete post-bootstrap setup | [setup.md](setup.md) |
| `dotfiles bootstrap` | Full machine setup | [bootstrap.md](bootstrap.md) |
| `dotfiles destroy` | Remove dotfiles | [destroy.md](destroy.md) |

## Utility

| Command | Description |
|---------|-------------|
| `dotfiles help` | Show help message |
| `dotfiles --version` | Show version |

## Common Workflows

### Daily Usage

```bash
# Check for issues
dotfiles doctor --quick

# Pull latest changes
dotfiles update

# See what's pending
dotfiles status
```

### Setting Up New Machine

```bash
# Bootstrap (essential tools)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/kidchenko/dotfiles/main/tools/bootstrap.sh)"

# Complete setup (packages, extensions, ssh, defaults)
dotfiles setup

# Verify everything works
dotfiles doctor
```

### Keeping in Sync

```bash
# Pull and apply latest
dotfiles update

# Check for package updates
dotfiles packages outdated
```

### Editing Dotfiles

```bash
# Edit directly with chezmoi
chezmoi edit ~/.zshrc

# Preview changes
dotfiles status

# Apply changes
chezmoi apply

# Commit to git
cd ~/.local/share/chezmoi
git add -A && git commit -m "Update zshrc" && git push
```
