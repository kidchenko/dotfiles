# dotfiles update

Pull the latest changes from the remote repository and apply them.

## Usage

```bash
dotfiles update
```

## What It Does

1. Fetches changes from the remote git repository
2. Checks if there are new commits
3. Prompts you to confirm the update
4. Pulls the changes
5. Applies updated dotfiles with `chezmoi apply`

## Example

```bash
$ dotfiles update
[dotfiles] Checking for updates...
[dotfiles] New version available.
[dotfiles] Would you like to update? [y/n]: y
[dotfiles] Updated successfully!
```

## Automatic Check on Shell Login

The update script is called on shell login via `.zlogin`. If updates are available, you'll see a prompt:

```
[dotfiles] New version available.
[dotfiles] Would you like to update? [y/n]:
```

## Manual Update

If you prefer manual control:

```bash
# Just pull changes (don't apply)
cd ~/.local/share/chezmoi
git pull

# Then apply when ready
dotfiles apply
```

## Force Update

To update without prompts:

```bash
chezmoi update --force
```

## Checking Status

See if updates are available without applying:

```bash
# Check git status
dotfiles status

# Or directly
cd ~/.local/share/chezmoi && git fetch && git status
```

## Related Commands

- [dotfiles apply](apply.md) - Apply pending changes
- [dotfiles diff](diff.md) - Preview changes
- [dotfiles status](status.md) - Show git status
