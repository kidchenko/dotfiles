# @kidchenko's Dotfiles

Cross-platform dotfiles (macOS & Linux) managed with [Chezmoi](https://chezmoi.io/), following [XDG Base Directory](https://specifications.freedesktop.org/basedir-spec/latest/) conventions.

## Quick Start

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/kidchenko/dotfiles/main/tools/bootstrap.sh)"
```

## What's Included

- **Zsh** with Oh My Zsh, aliases, and functions
- **Git** configuration with templating support
- **Neovim** setup
- **Tmux** configuration
- **Global tools** management (npm, pip, dotnet)
- **VS Code** extensions sync
- **1Password** integration for secrets (SSH keys, tokens)
- **macOS defaults** automation

## Documentation

| Guide | Description |
|-------|-------------|
| [Installation](docs/installation.md) | Prerequisites, bootstrap options, manual install |
| [Customization](docs/customization.md) | Fork setup, global tools, VS Code, templating |
| [Structure](docs/structure.md) | Repository layout, XDG paths, key scripts |

## Dotfiles CLI

```bash
dotfiles help           # Show all commands
dotfiles doctor         # Health check
dotfiles install        # Install Homebrew packages
dotfiles extensions     # Install VS Code extensions
dotfiles defaults       # Apply macOS settings
dotfiles ssh            # Setup SSH keys with 1Password
dotfiles backup         # Backup projects
dotfiles cron           # Manage scheduled tasks
```

## Secrets Management (1Password)

SSH keys and secrets are stored in 1Password and restored automatically:

```bash
# First time setup
op signin                    # Sign in to 1Password
dotfiles ssh                 # Generate SSH key and store in 1Password

# On a new machine
op signin                    # Sign in to 1Password
chezmoi apply                # SSH keys restored from 1Password
```

Secrets are never stored in the git repo - only 1Password references in templates.

---

Built with care by [@kidchenko](https://github.com/kidchenko)
