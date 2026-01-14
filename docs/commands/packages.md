# dotfiles packages

Manage system packages across platforms (Homebrew on macOS/Linux, Chocolatey on Windows).

## Usage

```bash
dotfiles packages [SUBCOMMAND]
```

## Subcommands

| Subcommand | Description |
|------------|-------------|
| `install` | Install packages from manifest (default) |
| `cleanup` | Remove packages not in manifest |
| `list` | Show installed packages |
| `outdated` | Show packages with available updates |

## Examples

```bash
# Install all packages from Brewfile
dotfiles packages

# Same as above (explicit)
dotfiles packages install

# Check for unlisted packages
dotfiles packages cleanup

# Remove unlisted packages
dotfiles packages cleanup --force

# List all installed packages
dotfiles packages list

# Check for updates
dotfiles packages outdated
```

## Package Manifests

### macOS/Linux (Homebrew)

Packages are defined in `Brewfile` at the repository root:

```ruby
# Brewfile
brew "git"
brew "fzf"
cask "visual-studio-code"
```

### Windows (Chocolatey)

Packages are defined in `tools/os_installers/choco.ps1`.

## Verbose Output

The install command runs with `--verbose` by default, showing:

```
[dotfiles] Installing packages from Brewfile...
Using git
Using fzf
Installing ripgrep
Using bat
...
[dotfiles] Done! Run 'dotfiles packages cleanup' to remove unlisted packages.
```

## Checking for Updates

```bash
$ dotfiles packages outdated

Outdated Packages

node (18.0.0) < 20.0.0
python (3.11.0) < 3.12.0

Run 'brew upgrade' to update all packages
```

## Cleanup Workflow

1. **Preview** what would be removed:
   ```bash
   dotfiles packages cleanup
   ```

2. **Remove** unlisted packages:
   ```bash
   dotfiles packages cleanup --force
   ```

## Cross-Platform Behavior

| Platform | Package Manager | Manifest |
|----------|-----------------|----------|
| macOS | Homebrew | `Brewfile` |
| Linux | Homebrew | `Brewfile` |
| Windows | Chocolatey | `tools/os_installers/choco.ps1` |

## Related Commands

- [dotfiles extensions](extensions.md) - Install VS Code/browser extensions
- [dotfiles setup](setup.md) - Complete setup (includes packages)
