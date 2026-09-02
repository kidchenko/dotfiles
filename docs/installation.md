# Installation Guide

## Prerequisites

### macOS / Linux

**Required:**
- **curl** or **wget** - For downloading installers (`curl` ships with macOS)

**Automatically installed:**
- **Homebrew** - Package manager
- **Git** - Via Homebrew, the system package manager (apt/dnf/yum/pacman/zypper/apk),
  or the Xcode Command Line Tools as a last resort
- **Chezmoi** - Dotfiles manager
- **Oh My Zsh** - Zsh framework
- **1Password CLI** - For secrets management (optional but recommended)

### Windows

**Required:** nothing. Windows PowerShell 5.1 ships with every supported
version of Windows, and that is all `bootstrap.ps1` needs to start.

**Automatically installed:**
- **Chocolatey** - Package manager (requires administrator; the script elevates via UAC)
- **Git** - Installed via Chocolatey
- **Chezmoi** - Dotfiles manager
- **PowerShell modules** - posh-git, Terminal-Icons, PSReadLine, PSFzf
- **PowerShell 7** - Installed as an essential package

### Optional
- [Nerd Font](https://www.nerdfonts.com/) - For icons in terminal prompts
  (installed automatically as part of the essential packages)

## Quick Install

Run this single command on a fresh machine.

**macOS / Linux:**

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/kidchenko/dotfiles/main/tools/bootstrap.sh)"
```

**Windows** (PowerShell — no prerequisites):

```powershell
irm https://raw.githubusercontent.com/kidchenko/dotfiles/main/tools/bootstrap.ps1 | iex
```

To pass options such as `-DryRun`, use a script block — `iex` cannot forward
arguments to a piped script:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/kidchenko/dotfiles/main/tools/bootstrap.ps1))) -DryRun
```

## What Gets Installed

The bootstrap process installs essential tools only:

**macOS / Linux:**

1. Install Homebrew
2. Install git, then refresh the shell's command lookup
3. Install Chezmoi dotfiles manager
4. Apply all dotfile configurations
5. Install essential packages from `Brewfile.essential`
6. Install Oh My Zsh and plugins
7. Create project directories
8. Setup the `dotfiles` CLI command

**Windows:**

1. Elevate via UAC (Chocolatey requires administrator)
2. Install Chocolatey, then refresh the session environment
3. Install git, then refresh again
4. Install Chezmoi dotfiles manager
5. Apply all dotfile configurations
6. Install essential packages from `packages.essential.config`
7. Install PowerShell modules
8. Create project directories
9. Setup the `dotfiles` CLI shim in `~/.local/bin`

Steps 2 and 3 refresh `PATH` in-process with `Update-SessionEnvironment`, so the
run can use tools it just installed without restarting the shell. This is the
Windows equivalent of `eval "$(brew shellenv)"` on macOS.

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

macOS / Linux:

```bash
exec zsh
```

Windows — refresh the current session, or open a new PowerShell window:

```powershell
refreshenv
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
