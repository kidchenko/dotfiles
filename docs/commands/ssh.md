# dotfiles ssh

Generate SSH keys and store them securely in 1Password.

## Usage

```bash
dotfiles ssh [OPTIONS]
```

## Options

| Option | Description |
|--------|-------------|
| `--vault NAME` | 1Password vault name (default: development) |
| `--name NAME` | Key name in 1Password (default: SSH Key) |
| `--help` | Show help message |

## Examples

```bash
# Generate SSH key with defaults
dotfiles ssh

# Use a different vault
dotfiles ssh --vault personal

# Custom key name
dotfiles ssh --name "GitHub SSH Key"
```

## Prerequisites

1. **1Password CLI** must be installed:
   ```bash
   brew install 1password-cli
   ```

2. **Sign in** to 1Password:
   ```bash
   op signin
   ```

## What It Does

1. Checks if you're signed in to 1Password
2. Checks if a key already exists (prompts to overwrite)
3. Creates `~/.ssh` directory if needed
4. Generates an Ed25519 SSH key **directly in 1Password**
5. Displays the public key for you to copy
6. Offers to configure 1Password SSH agent

## Key Storage

The key is stored in 1Password at:
```
op://development/SSH Key/
├── private key    # Ed25519 private key
└── public key     # Ed25519 public key
```

**The private key never touches your disk during generation.**

## Output Example

```
SSH Key Setup with 1Password

[ssh] Generating Ed25519 SSH key in 1Password (vault: development)...
[ssh] SSH key generated and stored in 1Password!

Public Key (add to GitHub/GitLab):

ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... you@example.com

Next steps:
  1. Copy the public key above
  2. Add it to GitHub: https://github.com/settings/ssh/new
  3. Add it to GitLab: https://gitlab.com/-/profile/keys

To restore SSH key on a new machine:
  chezmoi apply  # Key will be restored from 1Password
```

## Restoring Keys on New Machine

On a new machine, the keys are automatically restored:

```bash
# Sign in to 1Password
op signin

# Apply dotfiles (includes SSH keys)
chezmoi apply
```

The chezmoi templates in `home/private_dot_ssh/` pull keys from 1Password:

```gotemplate
# private_id_ed25519.tmpl
{{- if and (index . "onepassword") .onepassword -}}
{{- onepasswordRead "op://development/SSH Key/private key" -}}
{{- end -}}
```

## 1Password SSH Agent

For maximum security, you can use 1Password as your SSH agent:

1. Open **1Password app** → **Settings** → **Developer**
2. Enable **Use the SSH agent**
3. Enable **Integrate with 1Password CLI**

With this, you never need the private key on disk at all.

Your SSH config (`~/.ssh/config`) is set up to use the agent:

```
Host *
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
```

## Testing SSH Connection

After setup, test your GitHub connection:

```bash
ssh -T git@github.com
# Hi username! You've successfully authenticated...
```

## Troubleshooting

### "Not signed in to 1Password"

```bash
op signin
```

### Key not found in 1Password

Run `dotfiles ssh` again to generate a new key.

### SSH connection fails

1. Check key exists: `ls -la ~/.ssh/id_ed25519`
2. Check permissions: `chmod 600 ~/.ssh/id_ed25519`
3. Verify public key added to GitHub/GitLab
4. Test: `ssh -vT git@github.com`

## Related Commands

- [dotfiles doctor](doctor.md) - Check SSH key status
- [dotfiles apply](apply.md) - Restore keys from 1Password
