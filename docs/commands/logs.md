# dotfiles logs

View cron job logs.

## Usage

```bash
dotfiles logs [LOG_NAME]
```

## Arguments

| Argument | Description |
|----------|-------------|
| (none) | List all available logs |
| `backup` | View backup cron log |
| `brew` | View Homebrew bundle log |

## Examples

```bash
# List available logs
dotfiles logs

# View backup log
dotfiles logs backup

# View brew bundle log
dotfiles logs brew
```

## Log Location

Logs are stored in `~/.local/log/`:

| Log File | Source |
|----------|--------|
| `backup-cron.log` | Weekly backup job |
| `brew-bundle.log` | Weekly Homebrew update |

## Example: List Logs

```
$ dotfiles logs
Available Logs

  backup (2.1M) - 2024-01-15 02:00
  brew-bundle (156K) - 2024-01-15 09:00

View a log: dotfiles logs <name>
```

## Example: View Log

```
$ dotfiles logs backup
[2024-01-14 02:00:01] === Starting weekly backup ===
[2024-01-14 02:00:05] Backup completed successfully
[2024-01-14 02:00:05] Cleaning up old backups (keeping 2 most recent)...
[2024-01-14 02:00:05] === Finished ===
```

Logs open in `less` with `+G` (start at end).

## Log Rotation

Logs are not automatically rotated. To manage size:

```bash
# Check log sizes
ls -lh ~/.local/log/

# Clear a log
: > ~/.local/log/backup-cron.log

# Or delete old logs
rm ~/.local/log/*.log
```

## Troubleshooting Cron Jobs

If cron jobs aren't working:

1. **Check logs exist:**
   ```bash
   ls ~/.local/log/
   ```

2. **Check cron is running:**
   ```bash
   crontab -l
   ```

3. **Check log directory permissions:**
   ```bash
   ls -la ~/.local/log/
   ```

4. **Run job manually:**
   ```bash
   bash ~/.local/share/chezmoi/cron/backup.sh
   ```

## Related Commands

- [dotfiles cron](cron.md) - Manage scheduled tasks
- [dotfiles backup](backup.md) - Manual backup
