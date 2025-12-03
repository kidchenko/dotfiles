# dotfiles install

Install Homebrew packages from the Brewfile.

## Usage

```bash
dotfiles install [OPTIONS]
```

## Options

All options are passed to `brew bundle install`:

| Option | Description |
|--------|-------------|
| `--verbose` | Show detailed output |
| `--no-lock` | Don't generate a Brewfile.lock.json |

## Examples

```bash
# Install all packages
dotfiles install

# Verbose output
dotfiles install --verbose
```

## What It Does

Runs `brew bundle install` with the Brewfile at `~/.local/share/chezmoi/Brewfile`.

This installs:
- **Formulae** (CLI tools)
- **Casks** (GUI applications)
- **Mac App Store apps** (via `mas`)

## Brewfile Location

The Brewfile is located at:
```
~/.local/share/chezmoi/Brewfile
```

Or in the source repository:
```
dotfiles/Brewfile
```

## Brewfile Format

```ruby
# Taps (third-party repositories)
tap "homebrew/bundle"

# Formulae (CLI tools)
brew "git"
brew "chezmoi"
brew "fzf"

# Casks (GUI apps)
cask "visual-studio-code"
cask "1password"

# Mac App Store apps
mas "Xcode", id: 497799835
```

## Adding Packages

1. Edit the Brewfile
2. Run `dotfiles install`

```bash
# Edit Brewfile
dotfiles edit
# Navigate to Brewfile

# Install new packages
dotfiles install
```

## Checking What's Installed

```bash
# List all installed formulae
brew list

# List all installed casks
brew list --cask

# Check what's in Brewfile but not installed
brew bundle check --file=~/.local/share/chezmoi/Brewfile
```

## Related Commands

- [dotfiles cleanup](cleanup.md) - Remove packages not in Brewfile
- [dotfiles doctor](doctor.md) - Check Homebrew status
