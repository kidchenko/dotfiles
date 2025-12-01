# Installation Guide

## Prerequisites

- **Git**: For cloning the repository
- **curl** or **wget**: For downloading Chezmoi
- **(Optional)** A [Nerd Font](https://www.nerdfonts.com/) for icons in prompts/themes

> The bootstrap script will install `yq` automatically if needed.

## Quick Install

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/kidchenko/dotfiles/main/tools/bootstrap.sh)"
```

## Manual Install

```bash
git clone https://github.com/kidchenko/dotfiles.git ~/dotfiles_source
cd ~/dotfiles_source
bash tools/bootstrap.sh
```

## Bootstrap Options

| Flag | Description |
|------|-------------|
| `--verbose` | Enable detailed output |
| `--dry-run` | Simulate without making changes |
| `--force-chezmoi-init` | Force Chezmoi re-initialization |
| `--repo <URL>` | Use a custom repository URL |

**Example:**
```bash
bash tools/bootstrap.sh --verbose --dry-run
```
