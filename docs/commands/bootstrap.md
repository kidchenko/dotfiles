# dotfiles bootstrap

Bootstrap dotfiles on a new machine. This is the main entry point for setting up a fresh system.

## Usage

```bash
# One-liner (recommended for new machines)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/kidchenko/dotfiles/main/tools/bootstrap.sh)"

# Or run locally
dotfiles bootstrap
```

## What It Does

The bootstrap script performs these steps in order:

### 1. Install Homebrew (macOS)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
Skipped on Linux.

### 2. Install Chezmoi
```bash
brew install chezmoi
# or on Linux
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
```

### 3. Install Homebrew Packages
```bash
brew bundle install --file=Brewfile
```
Installs all packages including 1password-cli.

### 4. Setup 1Password CLI
Prompts you to sign in if not already authenticated:
```bash
op signin
```

### 5. Setup SSH Keys
Checks for existing SSH keys:
- If key exists locally → Skip
- If key exists in 1Password → Will be restored by chezmoi
- If no key exists → Prompts to generate with `dotfiles ssh`

### 6. Apply Dotfiles
```bash
chezmoi init --apply https://github.com/kidchenko/dotfiles.git
```
Prompts for:
- Git name
- Git email
- Preferred editor

### 7. Install Oh My Zsh
```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### 8. Install Zsh Plugins
- zsh-autosuggestions
- zsh-syntax-highlighting
- zsh-nvm

### 9. Setup Cron Jobs
```bash
bash cron/setup-cron.sh
```
Sets up:
- Weekly Homebrew updates (Monday 9am)
- Weekly backups (Sunday 2am)

### 10. Install dotfiles CLI
```bash
ln -sf ~/.local/share/chezmoi/tools/dotfiles ~/.local/bin/dotfiles
```

## Post-Bootstrap

After bootstrap completes:

```bash
# Restart your shell
exec zsh

# Verify setup
dotfiles doctor

# (Optional) Apply macOS defaults
dotfiles defaults

# (Optional) Install VS Code extensions
dotfiles extensions
```

## Re-running Bootstrap

It's safe to re-run bootstrap. Each step checks if it's already done:
- Homebrew installed? Skip
- Chezmoi installed? Skip
- Oh My Zsh installed? Skip
- etc.

## Troubleshooting

### Bootstrap fails to download

```bash
# Download manually
curl -O https://raw.githubusercontent.com/kidchenko/dotfiles/main/tools/bootstrap.sh
bash bootstrap.sh
```

### Homebrew installation fails

On Apple Silicon Macs, Homebrew installs to `/opt/homebrew`. The bootstrap script handles this automatically.

### Chezmoi prompts for data again

This happens if the config was corrupted. Check:
```bash
cat ~/.config/chezmoi/chezmoi.toml
```

### 1Password not detected

Make sure you're signed in:
```bash
op signin
op account list  # Should show your account
```

Then re-run:
```bash
chezmoi apply
```

## Related Commands

- [dotfiles doctor](doctor.md) - Verify setup
- [dotfiles apply](apply.md) - Apply dotfiles
- [dotfiles ssh](ssh.md) - Setup SSH keys
- [dotfiles destroy](destroy.md) - Uninstall
