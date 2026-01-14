# dotfiles packages

Manage all packages: system packages, global tools, and extensions.

## Usage

```bash
dotfiles packages [SUBCOMMAND]
```

## Subcommands

| Subcommand | Description |
|------------|-------------|
| `install` | Install system packages from Brewfile (default) |
| `cleanup` | Remove packages not in Brewfile |
| `list` | Show installed packages |
| `outdated` | Show packages with available updates |
| `global` | Install global tools (npm/pip/dotnet) |
| `extensions` | Install extensions (vscode/browser/all) |

## System Packages

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

### Package Manifests

| Platform | Package Manager | Manifest |
|----------|-----------------|----------|
| macOS | Homebrew | `Brewfile` |
| Linux | Homebrew | `Brewfile` |
| Windows | Chocolatey | `tools/os_installers/choco.ps1` |

## Global Tools

Install npm, pip, and dotnet global tools defined in `~/.config/dotfiles/config.yaml`.

```bash
dotfiles packages global
```

### Configuration

Edit `~/.config/dotfiles/config.yaml`:

```yaml
global_tools:
  npm:
    - typescript
    - prettier
    - eslint
  pip:
    - black
    - httpie
    - poetry
  dotnet:
    - dotnet-ef
    - dotnet-serve
```

## Extensions

Install VS Code and browser extensions.

```bash
# Install all extensions
dotfiles packages extensions

# VS Code only
dotfiles packages extensions vscode

# Browser only (Brave)
dotfiles packages extensions browser
```

### Configuration

| Config File | Description |
|-------------|-------------|
| `~/.config/dotfiles/vscode-extensions.txt` | VS Code extension IDs (one per line) |
| `~/.config/dotfiles/brave-extensions.txt` | Brave extension IDs (one per line) |

## Related Commands

- [dotfiles setup](setup.md) - Complete setup (includes all packages)
