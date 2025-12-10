# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it responsibly:

1. **Do NOT open a public issue** for security vulnerabilities
2. Email the maintainer directly or use GitHub's private vulnerability reporting
3. Include as much detail as possible:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

I will respond within 48 hours and work with you to understand and address the issue.

## Security Considerations

### Bootstrap Script

The one-line bootstrap command downloads and executes a script from the internet:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/kidchenko/dotfiles/main/tools/bootstrap.sh)"
```

**Before running this command:**

1. **Review the script first:**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/kidchenko/dotfiles/main/tools/bootstrap.sh | less
   ```

2. **Use a specific release** (recommended for stability):
   ```bash
   bash -c "$(curl -fsSL https://raw.githubusercontent.com/kidchenko/dotfiles/v1.0.0/tools/bootstrap.sh)"
   ```

3. **Run in dry-run mode** to preview changes:
   ```bash
   bash -c "$(curl -fsSL https://raw.githubusercontent.com/kidchenko/dotfiles/main/tools/bootstrap.sh)" -- --dry-run
   ```

### Secrets Management

This project uses **1Password CLI** for secrets management:

- SSH private keys are generated directly in 1Password (never touch disk during generation)
- Keys are retrieved via Chezmoi templates using `op://` references
- No secrets are stored in the repository

**If you don't use 1Password:**
- The bootstrap will skip 1Password integration
- You'll need to manage SSH keys manually
- Set `onepassword = false` in your Chezmoi config

### File Permissions

Sensitive files are managed with appropriate permissions:

- SSH keys: `0600` (owner read/write only)
- SSH config: `0644`
- Private directories use Chezmoi's `private_` prefix

### What This Project Does NOT Do

- Does not collect or transmit any data
- Does not phone home or check for updates automatically
- Does not install anything without your explicit action
- Does not modify system files outside your home directory (except Homebrew)

### Third-Party Dependencies

This project installs software from:

- **Homebrew** (macOS/Linux package manager)
- **apt** (Debian/Ubuntu packages)
- **Chocolatey** (Windows package manager)
- **npm/pip/dotnet** (language-specific tools)

Review the `Brewfile` and installer scripts to see exactly what gets installed.

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| main    | :white_check_mark: |
| < 1.0   | :x:                |

## Security Best Practices

When forking this repository:

1. **Change the repository URL** in `bootstrap.sh` to your own fork
2. **Review all scripts** before running them
3. **Use tagged releases** rather than `main` branch for stability
4. **Keep your fork updated** to receive security fixes
5. **Don't commit secrets** - use 1Password or another secrets manager
