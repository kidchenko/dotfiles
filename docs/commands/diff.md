# dotfiles diff

Show pending dotfile changes (what would be applied).

## Usage

```bash
dotfiles diff [FILE...]
```

## Arguments

| Argument | Description |
|----------|-------------|
| (none) | Show all pending changes |
| `FILE` | Show changes for specific file(s) |

## Examples

```bash
# Show all pending changes
dotfiles diff

# Show changes for specific file
dotfiles diff ~/.zshrc

# Show changes for multiple files
dotfiles diff ~/.zshrc ~/.gitconfig
```

## What It Shows

Displays a diff between:
- **Source:** Templates in `~/.local/share/chezmoi/home/`
- **Target:** Current files in your home directory

## Example Output

```diff
$ dotfiles diff
diff --git a/.zshrc b/.zshrc
--- a/.zshrc
+++ b/.zshrc
@@ -10,6 +10,7 @@ plugins=(
     git
     docker
+    kubectl
     zsh-autosuggestions
 )
```

## Understanding the Output

- Lines starting with `-` will be **removed**
- Lines starting with `+` will be **added**
- Context lines (no prefix) are unchanged

## Workflow

1. **Check what would change:**
   ```bash
   dotfiles diff
   ```

2. **If changes look good, apply:**
   ```bash
   dotfiles apply
   ```

3. **If you want to keep local changes:**
   ```bash
   chezmoi add ~/.zshrc  # Add local file to source
   ```

## No Output = No Changes

If `dotfiles diff` shows nothing, your dotfiles are in sync.

## Related Commands

- [dotfiles apply](apply.md) - Apply pending changes
- [dotfiles edit](edit.md) - Edit source files
- [dotfiles status](status.md) - Show git status
