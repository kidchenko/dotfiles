# dotfiles extensions

Install VS Code extensions from a configuration file.

## Usage

```bash
dotfiles extensions [OPTIONS]
```

## Options

| Option | Description |
|--------|-------------|
| `--verbose` | Show detailed output |
| `--dry-run` | Show what would be installed without installing |
| `--help` | Show help message |

## Examples

```bash
# Install all extensions
dotfiles extensions

# Preview what would be installed
dotfiles extensions --dry-run

# Verbose output
dotfiles extensions --verbose
```

## Prerequisites

VS Code must be installed with the `code` command available:

1. Open VS Code
2. Open Command Palette (Cmd+Shift+P)
3. Run "Shell Command: Install 'code' command in PATH"

## Configuration File

Extensions are listed in `~/.config/dotfiles/vscode-extensions.txt`:

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

# Comments start with #
# One extension ID per line
```

## Finding Extension IDs

1. Open VS Code Extensions view
2. Click on an extension
3. Copy the ID from the "Identifier" field (e.g., `ms-python.python`)

Or search on the [VS Code Marketplace](https://marketplace.visualstudio.com/vscode).

## What It Does

1. Reads extension IDs from the config file
2. Checks which are already installed
3. Installs missing extensions via `code --install-extension`

Already installed extensions are skipped (idempotent).

## Example Output

```
install_vscode_extensions: Starting VS Code extension installation...
install_vscode_extensions: Installing VS Code extension: ms-python.python...
install_vscode_extensions: Extension 'ms-python.python' installed successfully.
install_vscode_extensions: VS Code extension installation process finished.
install_vscode_extensions: Summary: Processed 10 extensions.
  Installed: 3
  Skipped (already installed): 7
  Failed: 0
```

## Exporting Current Extensions

To export your currently installed extensions:

```bash
code --list-extensions > ~/.config/dotfiles/vscode-extensions.txt
```

## Related Commands

- [dotfiles install](install.md) - Install Homebrew packages
- [dotfiles doctor](doctor.md) - Check setup status
