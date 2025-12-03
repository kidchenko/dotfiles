# dotfiles apply

Apply pending dotfile changes from the source repository to your home directory.

## Usage

```bash
dotfiles apply [OPTIONS]
```

## Options

All options are passed directly to `chezmoi apply`:

| Option | Description |
|--------|-------------|
| `--dry-run` | Preview changes without applying |
| `--force` | Apply even if conflicts exist |
| `--verbose` | Show detailed output |

## Examples

```bash
# Apply all pending changes
dotfiles apply

# Preview what would change
dotfiles apply --dry-run

# Force apply (overwrite local changes)
dotfiles apply --force

# Verbose output
dotfiles apply --verbose
```

## What It Does

1. Reads templates from `~/.local/share/chezmoi/home/`
2. Processes `.tmpl` files with your data from `~/.config/chezmoi/chezmoi.toml`
3. Copies/updates files to your home directory
4. Sets correct file permissions (private_, executable_)
5. Fetches secrets from 1Password (if configured)

## Template Processing

Files ending in `.tmpl` are processed as Go templates:

```gotemplate
# Example: dot_gitconfig.tmpl
[user]
    name = {{ .name }}
    email = {{ .email }}
```

Data comes from your chezmoi config:

```toml
# ~/.config/chezmoi/chezmoi.toml
[data]
    name = "Your Name"
    email = "you@example.com"
```

## 1Password Integration

If 1Password is configured, templates can fetch secrets:

```gotemplate
{{- onepasswordRead "op://vault/item/field" -}}
```

SSH keys are restored this way during apply.

## Previewing Changes

Always preview before applying:

```bash
# See what would change
dotfiles diff

# Or with apply
dotfiles apply --dry-run
```

## Handling Conflicts

If local files have been modified:

```bash
# See the differences
chezmoi diff ~/.zshrc

# Keep local changes (add to chezmoi)
chezmoi add ~/.zshrc

# Discard local changes (use source)
dotfiles apply --force
```

## Related Commands

- [dotfiles diff](diff.md) - Preview pending changes
- [dotfiles edit](edit.md) - Edit source files
- [dotfiles update](update.md) - Pull and apply from remote
