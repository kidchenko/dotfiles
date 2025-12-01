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

## Documentation

| Guide | Description |
|-------|-------------|
| [Installation](docs/installation.md) | Prerequisites, bootstrap options, manual install |
| [Customization](docs/customization.md) | Fork setup, global tools, VS Code, templating |
| [Structure](docs/structure.md) | Repository layout, XDG paths, key scripts |

## Quick Commands

```bash
chezmoi apply    # Apply dotfile changes
chezmoi update   # Pull and apply from remote
chezmoi diff     # Preview pending changes
```

---

Built with care by [@kidchenko](https://github.com/kidchenko)
