# Dotfiles CLI Commands

Complete reference for all `dotfiles` commands.

## Quick Reference

```bash
dotfiles help              # Show all commands
```

## Core Commands

| Command | Description | Documentation |
|---------|-------------|---------------|
| `dotfiles doctor` | Run health checks | [doctor.md](doctor.md) |
| `dotfiles apply` | Apply pending changes | [apply.md](apply.md) |
| `dotfiles update` | Pull and apply from remote | [update.md](update.md) |
| `dotfiles diff` | Preview pending changes | [diff.md](diff.md) |
| `dotfiles edit` | Edit source files | [edit.md](edit.md) |
| `dotfiles status` | Show git status | [status.md](status.md) |

## Package Management

| Command | Description | Documentation |
|---------|-------------|---------------|
| `dotfiles install` | Install Homebrew packages | [install.md](install.md) |
| `dotfiles cleanup` | List orphaned packages | [cleanup.md](cleanup.md) |
| `dotfiles extensions` | Install VS Code extensions | [extensions.md](extensions.md) |

## Maintenance

| Command | Description | Documentation |
|---------|-------------|---------------|
| `dotfiles backup` | Backup projects | [backup.md](backup.md) |
| `dotfiles cron` | Manage scheduled tasks | [cron.md](cron.md) |
| `dotfiles logs` | View cron job logs | [logs.md](logs.md) |

## System Setup

| Command | Description | Documentation |
|---------|-------------|---------------|
| `dotfiles ssh` | Generate SSH keys | [ssh.md](ssh.md) |
| `dotfiles defaults` | Apply macOS settings | [defaults.md](defaults.md) |
| `dotfiles bootstrap` | Full machine setup | [bootstrap.md](bootstrap.md) |
| `dotfiles destroy` | Remove dotfiles | [destroy.md](destroy.md) |

## Utility Commands

| Command | Description |
|---------|-------------|
| `dotfiles cd` | Print path to dotfiles source |
| `dotfiles help` | Show help message |

## Common Workflows

### Daily Usage

```bash
# Check status
dotfiles doctor --quick

# Apply any pending changes
dotfiles diff && dotfiles apply
```

### After Editing Dotfiles

```bash
# Edit a file
dotfiles edit ~/.zshrc

# Preview changes
dotfiles diff

# Apply changes
dotfiles apply

# Commit to git
cd $(dotfiles cd)
git add -A && git commit -m "Update zshrc" && git push
```

### Setting Up New Machine

```bash
# Bootstrap everything
bash -c "$(curl -fsSL https://raw.githubusercontent.com/kidchenko/dotfiles/main/tools/bootstrap.sh)"

# Verify setup
dotfiles doctor

# Apply macOS settings
dotfiles defaults

# Install VS Code extensions
dotfiles extensions
```

### Keeping in Sync

```bash
# Check for updates
dotfiles update

# Or manually pull
cd $(dotfiles cd) && git pull
dotfiles apply
```
