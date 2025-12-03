# dotfiles cron

Manage scheduled tasks (cron jobs).

## Usage

```bash
dotfiles cron [COMMAND]
```

## Commands

| Command | Description |
|---------|-------------|
| (none) | List scheduled tasks (same as `list`) |
| `list` | List scheduled tasks |
| `setup` | Install/update all cron jobs |

## Examples

```bash
# Show scheduled tasks
dotfiles cron

# Re-setup cron jobs
dotfiles cron setup
```

## Scheduled Tasks

| Schedule | Task | Description |
|----------|------|-------------|
| Monday 9am | `cron/update.sh` | Update Homebrew packages |
| Sunday 2am | `cron/backup.sh` | Backup projects (keeps 2) |

## Example Output

```
$ dotfiles cron
Scheduled Tasks

  ✓ Weekly brew bundle (Monday 9am)
  ✓ Weekly backup (Sunday 2am)
```

## Setup Cron Jobs

If cron jobs are missing:

```bash
dotfiles cron setup
```

This will:
1. Remove old dotfiles cron entries
2. Add new entries for all defined jobs

## Cron Job Scripts

### update.sh (Homebrew Updates)

Located at `cron/update.sh`:
- Runs `brew bundle install`
- Logs to `~/.local/log/brew-bundle.log`

### backup.sh (Project Backups)

Located at `cron/backup.sh`:
- Runs the backup script
- Keeps only 2 most recent backups
- Logs to `~/.local/log/backup-cron.log`

## Viewing Logs

```bash
# List all logs
dotfiles logs

# View specific log
dotfiles logs backup
dotfiles logs brew
```

## Adding New Cron Jobs

1. Create script in `cron/`:
   ```bash
   #!/usr/bin/env bash
   # cron/my-task.sh
   echo "Running my task..."
   ```

2. Edit `cron/setup-cron.sh`:
   ```bash
   CRON_JOBS=(
       "update.sh|0 9 * * 1|Weekly brew bundle (Monday 9am)"
       "backup.sh|0 2 * * 0|Weekly backup (Sunday 2am)"
       "my-task.sh|0 12 * * *|Daily task (noon)"  # Add here
   )
   ```

3. Run setup:
   ```bash
   dotfiles cron setup
   ```

## Cron Schedule Format

```
┌───────────── minute (0-59)
│ ┌───────────── hour (0-23)
│ │ ┌───────────── day of month (1-31)
│ │ │ ┌───────────── month (1-12)
│ │ │ │ ┌───────────── day of week (0-6, 0=Sunday)
│ │ │ │ │
* * * * *
```

Common patterns:
- `0 9 * * 1` - Monday at 9am
- `0 2 * * 0` - Sunday at 2am
- `0 */4 * * *` - Every 4 hours
- `30 8 * * 1-5` - Weekdays at 8:30am
- `0 0 1 * *` - First of each month at midnight

## Viewing Raw Crontab

```bash
crontab -l
```

## Removing Cron Jobs

Edit `cron/setup-cron.sh` and remove the entry, then:

```bash
dotfiles cron setup
```

Or manually:
```bash
crontab -e
# Remove the line
```

## Platform

**macOS only.** Linux uses different scheduling mechanisms (systemd timers, etc.).

## Related Commands

- [dotfiles backup](backup.md) - Manual backup
- [dotfiles logs](logs.md) - View cron logs
- [dotfiles doctor](doctor.md) - Check cron status
