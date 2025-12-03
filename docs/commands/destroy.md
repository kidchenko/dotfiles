# dotfiles destroy

Remove dotfiles and optionally all related state and tools.

## Usage

```bash
dotfiles destroy [OPTIONS]
```

## Options

| Option | Description |
|--------|-------------|
| (none) | Remove managed dotfiles only |
| `--all` | Also remove chezmoi state, zsh data, brew packages |
| `--deep` | Factory reset: remove all dev tools, caches, histories |
| `--force` | Skip confirmation prompts |
| `--help` | Show help message |

## Examples

```bash
# Remove dotfiles only (prompts for confirmation)
dotfiles destroy

# Full cleanup including brew packages
dotfiles destroy --all

# Factory reset (DESTRUCTIVE!)
dotfiles destroy --deep

# Skip confirmation
dotfiles destroy --force
```

## Removal Levels

### Default (no flags)

Removes only chezmoi-managed files:
- `~/.zshrc`
- `~/.gitconfig`
- `~/.config/zsh/*`
- `~/.config/nvim/*`
- Other files from `chezmoi managed`

### --all

Additionally removes:
- `~/.local/share/chezmoi` (dotfiles source)
- `~/.config/chezmoi` (chezmoi config)
- `~/.cache/chezmoi` (chezmoi cache)
- `~/.local/share/zsh` (zsh history)
- `~/.cache/zsh` (zsh cache)
- `~/.config/dotfiles` (dotfiles config)
- Homebrew packages from Brewfile

### --deep (Factory Reset)

Additionally removes:
- `~/.oh-my-zsh` (Oh My Zsh)
- Shell histories: `.zsh_history`, `.bash_history`, `.python_history`, etc.
- Node: `.npm`, `.yarn`, `.pnpm`, `.node_repl_history`
- Python: `.python_history`
- Ruby: `.gem`, `.bundle`, `.irb_history`
- Rust: `.cargo`, `.rustup`
- .NET: `.nuget`, `.dotnet`
- Java: `.gradle`, `.m2`
- PHP: `.composer`
- Other caches: `.cache`, `.local/share`, `.local/state`
- **All Homebrew packages** (not just Brewfile)

**Warning:** This is destructive and will require reinstalling everything.

## What Gets Preserved

Even with `--deep`, these are NOT removed:
- `~/.ssh` (SSH keys)
- `~/Documents`, `~/Downloads`, etc.
- Applications in `/Applications`
- Homebrew itself (just the packages)
- System files

## Confirmation

Without `--force`, you'll see a preview and confirmation:

```
[dotfiles] Dotfiles destroy script
[dotfiles] Mode: Full cleanup (--all)

[dotfiles] The following managed files will be removed:

  ~/.zshrc
  ~/.gitconfig
  ~/.config/zsh/aliases.sh
  ...

[dotfiles] Additional directories to clean (--all):

  ~/.local/share/chezmoi (chezmoi source)
  ~/.config/chezmoi (chezmoi config)
  ...

[dotfiles] Are you sure you want to remove all dotfiles? [y/N]
```

## Reinstalling After Destroy

After destroying, you can reinstall:

```bash
# Full reinstall
bash -c "$(curl -fsSL https://raw.githubusercontent.com/kidchenko/dotfiles/main/tools/bootstrap.sh)"

# Or if you still have the source
cd ~/dotfiles  # or wherever you cloned
bash tools/bootstrap.sh
```

## Related Commands

- [dotfiles bootstrap](bootstrap.md) - Install dotfiles
- [dotfiles doctor](doctor.md) - Check status
