# Customization Guide

## Forking for Personal Use

### 1. Fork the Repository

Fork this repository on GitHub to customize freely.

### 2. Update Bootstrap URL

In your fork, edit `tools/bootstrap.sh`:

```bash
DOTFILES_REPO="https://github.com/YOUR_USERNAME/dotfiles.git"
```

### 3. Bootstrap Your Fork

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/dotfiles/main/tools/bootstrap.sh)"
```

## Editing Dotfiles

### Using Chezmoi

```bash
# Open dotfiles directory in your editor
dotfiles edit

# Or edit a specific file
chezmoi edit ~/.zshrc

# Preview changes before applying
chezmoi diff

# Apply changes
chezmoi apply
```

### File Naming Conventions

Chezmoi uses special prefixes in the `home/` directory:

| Prefix | Meaning | Example |
|--------|---------|---------|
| `dot_` | Becomes `.` | `dot_zshrc` → `~/.zshrc` |
| `private_` | File permissions 0600 | `private_dot_ssh/` |
| `executable_` | File permissions +x | `executable_script.sh` |
| `.tmpl` | Go template processing | `dot_gitconfig.tmpl` |

### Adding New Dotfiles

```bash
# Add an existing file to chezmoi
chezmoi add ~/.some-config

# Add as a template
chezmoi add --template ~/.some-config

# The file appears in ~/.local/share/chezmoi/home/
```

## Machine-Specific Configuration

### Chezmoi Data

During `chezmoi init`, you'll be prompted for:
- **name** - Your git name
- **email** - Your git email
- **editor** - Preferred editor (vim/code/nvim)

These are stored in `~/.config/chezmoi/chezmoi.toml`:

```toml
[data]
    name = "Your Name"
    email = "you@example.com"
    editor = "code"
    onepassword = true
```

### Using Data in Templates

Access these values in `.tmpl` files:

```gotemplate
# In home/dot_gitconfig.tmpl
[user]
    name = {{ .name }}
    email = {{ .email }}

[core]
    editor = {{ .editor }}
```

### Conditional Configuration

Use Go template conditionals:

```gotemplate
# Different config for macOS vs Linux
{{ if eq .chezmoi.os "darwin" }}
# macOS specific config
{{ else if eq .chezmoi.os "linux" }}
# Linux specific config
{{ end }}

# Work vs personal machine
{{ if eq .email "work@company.com" }}
[includeIf "gitdir:~/work/"]
    path = ~/.gitconfig-work
{{ end }}
```

### Adding Custom Data

Edit `~/.config/chezmoi/chezmoi.toml`:

```toml
[data]
    name = "Your Name"
    email = "you@example.com"
    editor = "code"
    onepassword = true
    # Add custom data
    is_work_machine = false
    github_username = "yourusername"
```

Then use in templates:

```gotemplate
{{ if .is_work_machine }}
# Work-specific settings
{{ end }}
```

## Homebrew Packages

### Adding Packages

Edit the `Brewfile` in the repository root:

```ruby
# Formulae
brew "new-tool"

# Casks (macOS apps)
cask "new-app"

# Mac App Store apps (requires mas)
mas "App Name", id: 123456789
```

### Installing Packages

```bash
# Install all packages
dotfiles install

# Or directly with brew
brew bundle install --file=~/.local/share/chezmoi/Brewfile
```

### Checking for Orphaned Packages

```bash
# List packages not in Brewfile
dotfiles cleanup

# Remove orphaned packages
dotfiles cleanup --force
```

## Global Development Tools

### Configuration File

Edit `~/.config/dotfiles/config.yaml`:

```yaml
global_tools:
  npm:
    - typescript
    - prettier
    - eslint
    - http-server
    - @angular/cli

  pip:
    - black
    - flake8
    - httpie
    - pipenv

  dotnet:
    - dotnet-ef
    - dotnet-outdated-tool
```

### Installing Tools

```bash
# Install all global tools
bash tools/install_global_tools.sh

# With verbose output
bash tools/install_global_tools.sh --verbose

# Dry run (show what would be installed)
bash tools/install_global_tools.sh --dry-run
```

## VS Code Extensions

### Configuration File

Edit `~/.config/dotfiles/vscode-extensions.txt`:

```
# Language Support
ms-python.python
golang.go
rust-lang.rust-analyzer

# Formatting
esbenp.prettier-vscode
dbaeumer.vscode-eslint

# Themes
dracula-theme.theme-dracula
pkief.material-icon-theme

# Productivity
eamodio.gitlens
vscodevim.vim
```

### Installing Extensions

```bash
# Install all extensions
dotfiles extensions

# With verbose output
bash tools/install_vscode_extensions.sh --verbose

# Dry run
bash tools/install_vscode_extensions.sh --dry-run
```

## Shell Customization

### Aliases

Edit `home/dot_config/zsh/aliases.sh`:

```bash
# Add your custom aliases
alias myalias='some-command'
```

### Functions

Edit `home/dot_config/zsh/functions.sh`:

```bash
# Add custom functions
myfunction() {
    echo "Hello from myfunction"
}
```

### Exports

Edit `home/dot_config/zsh/exports.sh`:

```bash
# Add environment variables
export MY_VAR="value"
```

### Oh My Zsh Plugins

Edit `home/dot_zshrc.tmpl`:

```bash
plugins=(
    git
    docker
    kubectl
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-nvm
    # Add more plugins here
)
```

## macOS Defaults

### Customizing Settings

Edit `tools/os_setup/macos_config.sh` to add or modify settings:

```bash
# Example: Change Dock icon size
defaults write com.apple.dock tilesize -int 36

# Example: Different hot corner
defaults write com.apple.dock wvous-tr-corner -int 4  # Desktop
```

### Applying Settings

```bash
dotfiles defaults
```

**Note:** Some settings require logout/restart to take effect.

## Scheduled Tasks

### Current Cron Jobs

| Schedule | Script | Purpose |
|----------|--------|---------|
| Monday 9am | `cron/update.sh` | Update Homebrew packages |
| Sunday 2am | `cron/backup.sh` | Backup projects (keeps 2) |

### Adding New Cron Jobs

1. Create your script in `cron/`:

```bash
#!/usr/bin/env bash
# cron/my-task.sh
echo "Running my task..."
```

2. Edit `cron/setup-cron.sh`:

```bash
CRON_JOBS=(
    "update.sh|0 9 * * 1|Weekly brew bundle (Monday 9am)"
    "backup.sh|0 2 * * 0|Weekly backup (Sunday 2am)"
    "my-task.sh|0 12 * * *|Daily task (noon)"  # Add your job
)
```

3. Re-run setup:

```bash
dotfiles cron setup
```

### Cron Schedule Format

```
┌───────────── minute (0-59)
│ ┌───────────── hour (0-23)
│ │ ┌───────────── day of month (1-31)
│ │ │ ┌───────────── month (1-12)
│ │ │ │ ┌───────────── day of week (0-6, 0=Sunday)
│ │ │ │ │
* * * * *
```

Examples:
- `0 9 * * 1` - Monday at 9am
- `0 2 * * 0` - Sunday at 2am
- `0 */4 * * *` - Every 4 hours
- `30 8 * * 1-5` - Weekdays at 8:30am

## 1Password Integration

### Storing Secrets

Secrets are stored in 1Password and accessed via templates:

```gotemplate
# In a .tmpl file
{{ onepasswordRead "op://vault/item/field" }}
```

### SSH Keys

SSH keys are generated directly in 1Password:

```bash
dotfiles ssh
```

Templates in `home/private_dot_ssh/` restore them:

```gotemplate
# private_id_ed25519.tmpl
{{- if and (index . "onepassword") .onepassword -}}
{{- onepasswordRead "op://development/SSH Key/private key" -}}
{{- end -}}
```

### Adding Other Secrets

1. Store the secret in 1Password
2. Reference it in your template:

```gotemplate
# Example: API key in a config file
api_key = {{ onepasswordRead "op://development/My API/credential" }}
```

## Testing Changes

### Preview Before Applying

```bash
# See what would change
chezmoi diff

# Apply to a different directory for testing
chezmoi apply --destination=/tmp/test-dotfiles
```

### Doctor Check

After changes, verify everything works:

```bash
dotfiles doctor
```
