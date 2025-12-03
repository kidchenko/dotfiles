# dotfiles status

Show git status of the dotfiles source repository.

## Usage

```bash
dotfiles status [GIT_OPTIONS]
```

## Options

All options are passed to `git status`:

| Option | Description |
|--------|-------------|
| `-s` | Short format |
| `-b` | Show branch info |
| `--porcelain` | Machine-readable format |

## Examples

```bash
# Show full status
dotfiles status

# Short format
dotfiles status -s

# Short with branch
dotfiles status -sb
```

## What It Shows

Runs `git status` in `~/.local/share/chezmoi`, showing:
- Current branch
- Uncommitted changes
- Untracked files
- Ahead/behind remote

## Example Output

```
$ dotfiles status
On branch main
Your branch is up to date with 'origin/main'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
        modified:   home/dot_zshrc.tmpl

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        home/dot_config/new-app/

no changes added to commit (use "git add" and/or "git commit -a")
```

## Workflow

1. **Check status:**
   ```bash
   dotfiles status
   ```

2. **Stage changes:**
   ```bash
   cd ~/.local/share/chezmoi
   git add -A
   ```

3. **Commit:**
   ```bash
   git commit -m "Update configuration"
   ```

4. **Push:**
   ```bash
   git push
   ```

## Quick Git Commands

```bash
# Navigate to dotfiles
cd $(dotfiles cd)

# Or use subshell
(cd ~/.local/share/chezmoi && git log --oneline -5)
```

## Related Commands

- [dotfiles diff](diff.md) - Show pending chezmoi changes
- [dotfiles edit](edit.md) - Edit source files
- [dotfiles update](update.md) - Pull from remote
