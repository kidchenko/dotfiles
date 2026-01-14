# dotfiles setup

Complete post-bootstrap setup - installs packages, extensions, SSH keys, and system defaults in one command.

## Usage

```bash
dotfiles setup
```

## What It Does

Runs these steps in order:

| Step | Description |
|------|-------------|
| 1 | Setup SSH keys with 1Password |
| 2 | Install packages from Brewfile |
| 3 | Install VS Code extensions |
| 4 | Install global tools (npm/pip/dotnet) |
| 5 | Install browser extensions |
| 6 | Setup cron jobs |
| 7 | Apply macOS defaults (macOS only) |

## Example Output

```
$ dotfiles setup

[dotfiles] Running complete setup...

[dotfiles] Step 1/7: Setting up SSH keys...
...

[dotfiles] Step 2/7: Installing packages...
Using git
Using fzf
Installing ripgrep
...

[dotfiles] Step 3/7: Installing VS Code extensions...
...

[dotfiles] Step 4/7: Installing global tools (npm/pip/dotnet)...
...

[dotfiles] Step 5/7: Installing browser extensions...
...

[dotfiles] Step 6/7: Setting up cron jobs...
...

[dotfiles] Step 7/7: Applying system defaults...
...

[dotfiles] Setup complete!
[dotfiles] Run 'dotfiles doctor' to verify everything is configured correctly.
```

## When to Use

Run `dotfiles setup` after bootstrap to complete your machine setup:

```bash
# 1. Bootstrap (essential tools only)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/kidchenko/dotfiles/main/tools/bootstrap.sh)"

# 2. Complete setup
dotfiles setup

# 3. Verify
dotfiles doctor
```

## Running Individual Steps

If you prefer to run steps individually:

```bash
dotfiles ssh              # SSH keys
dotfiles packages         # Packages
dotfiles extensions       # Extensions
dotfiles cron setup       # Cron jobs
dotfiles defaults         # macOS defaults
```

## Cross-Platform

On non-macOS systems, the macOS defaults step is automatically skipped.

## Related Commands

- [dotfiles bootstrap](bootstrap.md) - Initial machine setup
- [dotfiles doctor](doctor.md) - Verify setup
- [dotfiles packages](packages.md) - Manage packages
- [dotfiles extensions](extensions.md) - Install extensions
