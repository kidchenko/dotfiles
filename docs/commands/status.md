# dotfiles status

Show pending changes - combines chezmoi diff and git status in one view.

## Usage

```bash
dotfiles status
```

## What It Shows

1. **Pending dotfile changes** - Files that differ between source and target (via `chezmoi diff`)
2. **Git status** - Uncommitted changes in the dotfiles repository

## Example Output

```
$ dotfiles status

Dotfiles Changes

Pending dotfile changes:
diff --git a/.zshrc b/.zshrc
--- a/.zshrc
+++ b/.zshrc
@@ -10,6 +10,7 @@
 export EDITOR="nvim"
+export VISUAL="code"

Git Status
 M home/dot_zshrc.tmpl
?? home/dot_config/new-app/
```

When everything is in sync:

```
$ dotfiles status

Dotfiles Changes

No pending dotfile changes

Git Status
```

## Workflow

1. **Check status:**

   ```bash
   dotfiles status
   ```

2. **Apply pending changes:**

   ```bash
   chezmoi apply
   ```

3. **Commit to git:**

   ```bash
   cd ~/.local/share/chezmoi
   git add -A && git commit -m "Update config" && git push
   ```

## Understanding the Output

### Dotfiles Changes Section

Shows what `chezmoi apply` would change in your home directory:

- Lines with `-` will be removed
- Lines with `+` will be added
- "No pending dotfile changes" means source and target are in sync

### Git Status Section

Shows uncommitted changes in `~/.local/share/chezmoi`:

- `M` - Modified file
- `??` - Untracked file
- `A` - Added file
- `D` - Deleted file

## Related Commands

- [dotfiles update](update.md) - Pull and apply from remote
- [dotfiles doctor](doctor.md) - Run health checks
