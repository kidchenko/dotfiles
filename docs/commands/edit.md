# dotfiles edit

Edit dotfiles source files.

## Usage

```bash
dotfiles edit [FILE]
```

## Arguments

| Argument | Description |
|----------|-------------|
| (none) | Open dotfiles directory in your editor |
| `FILE` | Edit specific file's source in chezmoi |

## Examples

```bash
# Open entire dotfiles directory
dotfiles edit

# Edit specific file
dotfiles edit ~/.zshrc

# Edit gitconfig
dotfiles edit ~/.gitconfig
```

## What It Does

### Without arguments

Opens `~/.local/share/chezmoi` in your configured editor (VS Code by default).

### With a file argument

Opens the **source** file in chezmoi for the target file.

For example:
- `dotfiles edit ~/.zshrc` → Opens `~/.local/share/chezmoi/home/dot_zshrc.tmpl`
- `dotfiles edit ~/.gitconfig` → Opens `~/.local/share/chezmoi/home/dot_gitconfig.tmpl`

## Editor Configuration

The editor is determined by:
1. `$EDITOR` environment variable
2. Default: `code` (VS Code)

Set your preferred editor:
```bash
# In ~/.config/zsh/exports.sh
export EDITOR="nvim"  # or vim, code, etc.
```

## Workflow

1. **Edit source files:**
   ```bash
   dotfiles edit ~/.zshrc
   ```

2. **Preview changes:**
   ```bash
   dotfiles diff
   ```

3. **Apply changes:**
   ```bash
   dotfiles apply
   ```

4. **Commit to git:**
   ```bash
   cd ~/.local/share/chezmoi
   git add -A
   git commit -m "Update zshrc"
   git push
   ```

## Direct Chezmoi Edit

You can also use chezmoi directly:

```bash
# Edit with chezmoi (applies after saving)
chezmoi edit ~/.zshrc

# Edit without auto-apply
chezmoi edit --apply=false ~/.zshrc
```

## Finding Source Files

To find where a target file's source is:

```bash
chezmoi source-path ~/.zshrc
# ~/.local/share/chezmoi/home/dot_zshrc.tmpl
```

## Related Commands

- [dotfiles diff](diff.md) - Preview changes
- [dotfiles apply](apply.md) - Apply changes
- [dotfiles status](status.md) - Show git status
