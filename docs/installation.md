# Installation Guide

## Prerequisites

### Required
- **Git** - For cloning the repository
- **curl** or **wget** - For downloading installers

### Automatically Installed
The bootstrap script will install these for you:
- **Homebrew** (macOS) - Package manager
- **Chezmoi** - Dotfiles manager
- **Oh My Zsh** - Zsh framework
- **1Password CLI** - For secrets management (optional but recommended)

### Optional
- [Nerd Font](https://www.nerdfonts.com/) - For icons in terminal prompts

## Quick Install

Run this single command on a fresh machine:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/kidchenko/dotfiles/main/tools/bootstrap.sh)"
```

## What Gets Installed

The bootstrap process installs essential tools only:

1. Install Homebrew (macOS only)
2. Install Chezmoi dotfiles manager
3. Apply all dotfile configurations
4. Install essential packages from `Brewfile.essential`
5. Install Oh My Zsh and plugins
6. Setup the `dotfiles` CLI command

After bootstrap, run `dotfiles setup` for complete installation (full packages, extensions, SSH keys, system defaults).

## Manual Install

If you prefer more control:

```bash
# Clone the repository
git clone https://github.com/kidchenko/dotfiles.git ~/dotfiles

# Run bootstrap
cd ~/dotfiles
bash tools/bootstrap.sh
```

## Step-by-Step Install

For maximum control, run each step manually:

```bash
# 1. Install Homebrew (macOS)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install Chezmoi
brew install chezmoi

# 3. Initialize dotfiles
chezmoi init https://github.com/kidchenko/dotfiles.git

# 4. Preview changes
chezmoi diff

# 5. Apply dotfiles
chezmoi apply

# 6. Install packages
dotfiles packages

# 7. Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# 8. Install Zsh plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/lukechilds/zsh-nvm ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-nvm

# 9. Setup cron jobs
bash ~/.local/share/chezmoi/cron/setup-cron.sh

# 10. Link dotfiles CLI
ln -sf ~/.local/share/chezmoi/tools/dotfiles ~/.local/bin/dotfiles
```

## Post-Installation

### 1. Restart Your Shell

```bash
exec zsh
```

### 2. Complete Setup

Run the full setup to install packages, extensions, SSH keys, and system defaults:

```bash
dotfiles setup
```

Or run individual steps:

```bash
dotfiles ssh              # Setup SSH keys
dotfiles packages         # Install packages
dotfiles extensions       # Install extensions
dotfiles defaults         # Apply macOS defaults
```

### 3. Verify Installation

```bash
dotfiles doctor
```

This checks:
- Core tools (chezmoi, git, zsh, homebrew)
- 1Password CLI authentication
- SSH keys
- XDG directories
- Shell configuration
- Git configuration
- Symlink health
- Scheduled tasks

## Updating

After installation, keep your dotfiles up to date:

```bash
# Check for updates and apply
dotfiles update

# Or manually
chezmoi update
```

## Troubleshooting

### Bootstrap fails to download

If curl/wget fails, manually download and run:

```bash
curl -O https://raw.githubusercontent.com/kidchenko/dotfiles/main/tools/bootstrap.sh
bash bootstrap.sh
```

### Chezmoi conflicts

If chezmoi reports conflicts:

```bash
# See what would change
chezmoi diff

# Force apply (overwrites local changes)
chezmoi apply --force
```

### 1Password not authenticated

```bash
# Sign in
op signin

# Verify
op account list

# Re-apply dotfiles to get secrets
chezmoi apply
```

### SSH key not working

```bash
# Check if key exists
ls -la ~/.ssh/id_ed25519

# If missing, restore from 1Password
op signin
chezmoi apply

# Or generate new key
dotfiles ssh
```

### Zsh plugins missing

```bash
# Reinstall plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

### Cron jobs not running

```bash
# Check current crontab
crontab -l

# Re-setup cron jobs
dotfiles cron setup

# View logs
dotfiles logs
```

## Uninstalling

See the [Structure Guide](structure.md#uninstalling) for uninstall options.
