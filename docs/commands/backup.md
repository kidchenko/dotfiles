# dotfiles backup

Backup project folders to a zip archive.

## Usage

```bash
dotfiles backup [COMMAND]
```

## Commands

| Command | Description |
|---------|-------------|
| (none) | Create a new backup |
| `list` | List available backups |
| `restore` | Restore from a backup |

## Examples

```bash
# Create a backup
dotfiles backup

# List all backups
dotfiles backup list

# Restore from backup
dotfiles backup restore
```

## What Gets Backed Up

The backup script (`scripts/backup/backup-projects.sh`) backs up your project directories.

Default location: `~/Backups/tmp_project_backups/`

## Backup Retention

When run via cron, only **2 backups** are kept:
- Current week's backup
- Previous week's backup

Older backups are automatically deleted.

## Scheduled Backups

A cron job runs backups automatically:
- **Schedule:** Sunday 2am
- **Script:** `cron/backup.sh`
- **Log:** `~/.local/log/backup-cron.log`

Check scheduled backups:
```bash
dotfiles cron
```

## Manual Backup

```bash
dotfiles backup
```

## Viewing Backup Logs

```bash
# List available logs
dotfiles logs

# View backup log
dotfiles logs backup
```

## Backup Location

Backups are stored at:
```
~/Backups/tmp_project_backups/project-backup-YYYY-MM-DD.zip
```

## Configuring Backups

Edit `scripts/backup/backup-projects.sh` to customize:
- Which directories to backup
- Backup destination
- Exclusion patterns

## Related Commands

- [dotfiles cron](cron.md) - Manage scheduled tasks
- [dotfiles logs](logs.md) - View backup logs
