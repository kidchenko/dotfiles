# dotfiles cleanup

List or remove Homebrew packages that are not in the Brewfile.

## Usage

```bash
dotfiles cleanup [OPTIONS]
```

## Options

All options are passed to `brew bundle cleanup`:

| Option | Description |
|--------|-------------|
| (none) | List packages not in Brewfile (dry run) |
| `--force` | Actually remove the packages |

## Examples

```bash
# List orphaned packages (safe, doesn't remove)
dotfiles cleanup

# Remove orphaned packages
dotfiles cleanup --force
```

## What It Does

Compares installed Homebrew packages against the Brewfile and identifies:
- Formulae installed but not in Brewfile
- Casks installed but not in Brewfile

By default, it only **lists** these packages. Use `--force` to remove them.

## Example Output

```
$ dotfiles cleanup
[dotfiles] Checking for packages not in Brewfile...
Would uninstall formulae:
htop
tree

Would uninstall casks:
spotify
```

## When to Use

Use cleanup to:
- Find packages you installed manually but forgot about
- Keep your system in sync with your Brewfile
- Identify packages to add to your Brewfile

## Workflow

1. **List orphaned packages**
   ```bash
   dotfiles cleanup
   ```

2. **Decide for each package:**
   - Keep it? Add to Brewfile, then run `dotfiles install`
   - Remove it? Run `dotfiles cleanup --force`

3. **Add wanted packages to Brewfile:**
   ```ruby
   # In Brewfile
   brew "htop"
   cask "spotify"
   ```

4. **Or remove unwanted packages:**
   ```bash
   dotfiles cleanup --force
   ```

## Related Commands

- [dotfiles install](install.md) - Install Brewfile packages
- [dotfiles doctor](doctor.md) - Check Homebrew status
