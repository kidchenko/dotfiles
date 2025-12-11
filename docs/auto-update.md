# Auto-Update System

This document explains how the dotfiles repository keeps itself and your system packages automatically updated.

## Overview

The dotfiles use a **hybrid auto-update approach** with three mechanisms:

1. **Interactive Updates** - Prompted on shell login
2. **Scheduled Updates** - Cron jobs for background maintenance
3. **Manual Updates** - On-demand via CLI commands

## Architecture Diagram

```mermaid
flowchart TB
    subgraph "Update Triggers"
        LOGIN[Shell Login]
        CRON[Cron Scheduler]
        MANUAL[Manual Command]
    end

    subgraph "Update Mechanisms"
        ZLOGIN[.zlogin]
        UPDATE_SCRIPT[tools/update.sh]
        CRON_UPDATE[cron/update.sh]
        CRON_BACKUP[cron/backup.sh]
        CLI[dotfiles CLI]
    end

    subgraph "Actions"
        CHEZMOI[chezmoi update]
        BREW[brew bundle install]
        BACKUP[backup-projects.sh]
    end

    subgraph "Targets"
        DOTFILES[(Dotfiles)]
        PACKAGES[(Homebrew Packages)]
        PROJECTS[(Project Backups)]
    end

    LOGIN --> ZLOGIN
    ZLOGIN --> UPDATE_SCRIPT
    UPDATE_SCRIPT -->|User confirms| CHEZMOI
    CHEZMOI --> DOTFILES

    CRON -->|Monday 9am| CRON_UPDATE
    CRON_UPDATE --> BREW
    BREW --> PACKAGES

    CRON -->|Sunday 2am| CRON_BACKUP
    CRON_BACKUP --> BACKUP
    BACKUP --> PROJECTS

    MANUAL --> CLI
    CLI -->|dotfiles update| CHEZMOI
```

## Interactive Updates (Shell Login)

When you open a new terminal login shell, the system automatically checks for dotfiles updates.

### Flow Diagram

```mermaid
sequenceDiagram
    participant User
    participant Zsh as .zlogin
    participant Script as tools/update.sh
    participant Git as Git Repository
    participant Chezmoi

    User->>Zsh: Opens terminal (login shell)
    Zsh->>Script: Execute update check
    Script->>Git: git fetch
    Script->>Git: Compare LOCAL vs REMOTE

    alt No updates available
        Script-->>User: "Already up to date."
    else Updates available
        Script-->>User: "New version available."
        Script->>User: "Would you like to update? [y/n]"

        alt User accepts (y)
            User->>Script: y
            Script->>Chezmoi: chezmoi update
            Chezmoi->>Git: git pull
            Chezmoi->>Chezmoi: Apply templates
            Chezmoi-->>Script: Success
            Script-->>User: "Updated successfully!"
        else User declines (n)
            User->>Script: n
            Script-->>User: "Update skipped."
        end
    end
```

### How It Works

1. **Trigger**: `.zlogin` runs on every login shell
2. **Location**: `tools/update.sh`
3. **Process**:
   - Fetches remote changes (`git fetch`)
   - Compares local HEAD with remote HEAD
   - Prompts user if updates exist
   - Runs `chezmoi update` if user confirms

### Files Involved

| File | Purpose |
|------|---------|
| `home/dot_zlogin.tmpl` | Calls update script on login |
| `tools/update.sh` | Checks for updates and prompts user |

## Scheduled Updates (Cron Jobs)

Background tasks run automatically on a schedule to keep packages updated and backups current.

### Schedule Overview

```mermaid
gantt
    title Weekly Automation Schedule
    dateFormat  YYYY-MM-DD
    axisFormat %A

    section Homebrew
    Brew Bundle Update :active, 2024-01-01, 1d

    section Backups
    Project Backup     :2024-01-07, 1d
```

| Day | Time | Task | Script |
|-----|------|------|--------|
| Monday | 9:00 AM | Homebrew updates | `cron/update.sh` |
| Sunday | 2:00 AM | Project backups | `cron/backup.sh` |

### Cron Update Flow (Homebrew)

```mermaid
flowchart TD
    START[Cron triggers Monday 9am] --> DETECT{Detect Homebrew}

    DETECT -->|Apple Silicon| ARM[/opt/homebrew/bin/brew]
    DETECT -->|Intel Mac| INTEL[/usr/local/bin/brew]
    DETECT -->|Not found| ERROR[Exit with error]

    ARM --> UPDATE[brew update]
    INTEL --> UPDATE

    UPDATE --> BUNDLE[brew bundle install]
    BUNDLE --> LOG[Write to ~/.local/log/brew-bundle.log]
    LOG --> DONE[Complete]
```

### Cron Backup Flow

```mermaid
flowchart TD
    START[Cron triggers Sunday 2am] --> RUN[Run backup-projects.sh]
    RUN --> SUCCESS{Backup successful?}

    SUCCESS -->|Yes| CLEANUP[List backups by date]
    SUCCESS -->|No| LOG_ERROR[Log error and exit]

    CLEANUP --> KEEP[Keep 2 most recent]
    KEEP --> DELETE[Delete older backups]
    DELETE --> LOG[Write to ~/.local/log/backup-cron.log]
    LOG --> DONE[Complete]
```

### Cron Job Configuration

Jobs are defined in `cron/setup-cron.sh`:

```bash
CRON_JOBS=(
    "update.sh|0 9 * * 1|Weekly brew bundle (Monday 9am)"
    "backup.sh|0 2 * * 0|Weekly backup (Sunday 2am)"
)
```

### Cron Schedule Format

```
┌───────────── minute (0-59)
│ ┌───────────── hour (0-23)
│ │ ┌───────────── day of month (1-31)
│ │ │ ┌───────────── month (1-12)
│ │ │ │ ┌───────────── day of week (0-6, 0=Sunday)
│ │ │ │ │
* * * * *
```

### Files Involved

| File | Purpose |
|------|---------|
| `cron/setup-cron.sh` | Installs cron jobs |
| `cron/update.sh` | Homebrew bundle updates |
| `cron/backup.sh` | Project backup with retention |

## Complete System Flow

```mermaid
flowchart TB
    subgraph "Bootstrap (One-time)"
        BOOTSTRAP[tools/bootstrap.sh]
        INSTALL_BREW[Install Homebrew]
        INSTALL_CHEZMOI[Install Chezmoi]
        APPLY_DOTFILES[Apply Dotfiles]
        SETUP_CRON[Setup Cron Jobs]

        BOOTSTRAP --> INSTALL_BREW
        INSTALL_BREW --> INSTALL_CHEZMOI
        INSTALL_CHEZMOI --> APPLY_DOTFILES
        APPLY_DOTFILES --> SETUP_CRON
    end

    subgraph "Daily Operation"
        TERMINAL[Open Terminal]
        CHECK[Check for updates]
        PROMPT{Updates available?}
        USER_CHOICE{User accepts?}
        APPLY[chezmoi update]
        SKIP[Skip update]

        TERMINAL --> CHECK
        CHECK --> PROMPT
        PROMPT -->|Yes| USER_CHOICE
        PROMPT -->|No| DONE1[Continue to shell]
        USER_CHOICE -->|Yes| APPLY
        USER_CHOICE -->|No| SKIP
        APPLY --> DONE1
        SKIP --> DONE1
    end

    subgraph "Weekly Automation"
        CRON_MONDAY[Monday 9am]
        CRON_SUNDAY[Sunday 2am]
        BREW_UPDATE[Update Homebrew packages]
        BACKUP_RUN[Run backup]

        CRON_MONDAY --> BREW_UPDATE
        CRON_SUNDAY --> BACKUP_RUN
    end
```

## Log Files

All automated tasks log their output:

| Log File | Contents | View Command |
|----------|----------|--------------|
| `~/.local/log/brew-bundle.log` | Homebrew update output | `dotfiles logs brew` |
| `~/.local/log/backup-cron.log` | Backup operation output | `dotfiles logs backup` |

### Log Format

```
[2024-01-15 09:00:01] === Starting brew bundle install ===
[2024-01-15 09:00:05] Homebrew updated
[2024-01-15 09:00:30] Brew bundle install completed successfully
[2024-01-15 09:00:30] === Finished ===
```

## Manual Commands

| Command | Description |
|---------|-------------|
| `dotfiles update` | Pull and apply latest dotfiles |
| `dotfiles cron` | List scheduled tasks |
| `dotfiles cron setup` | Install/reinstall cron jobs |
| `dotfiles logs` | List available logs |
| `dotfiles logs brew` | View Homebrew update logs |
| `dotfiles logs backup` | View backup logs |

## Data Flow Diagram

```mermaid
flowchart LR
    subgraph "Remote"
        GH[(GitHub Repository)]
        BREW_REPO[(Homebrew)]
    end

    subgraph "Local Storage"
        CHEZMOI_DIR[~/.local/share/chezmoi]
        HOME_DIR[~/ dotfiles]
        LOG_DIR[~/.local/log]
        BACKUP_DIR[~/Backups]
    end

    subgraph "Configuration"
        BREWFILE[Brewfile]
        TEMPLATES[home/*.tmpl]
    end

    GH -->|git pull| CHEZMOI_DIR
    CHEZMOI_DIR -->|chezmoi apply| HOME_DIR

    BREWFILE --> BREW_REPO
    BREW_REPO -->|brew bundle| HOME_DIR

    TEMPLATES -->|render| HOME_DIR

    HOME_DIR -.->|logs| LOG_DIR
    HOME_DIR -.->|backup| BACKUP_DIR
```

## State Diagram

```mermaid
stateDiagram-v2
    [*] --> Checking: Shell login

    Checking --> UpToDate: No remote changes
    Checking --> UpdateAvailable: Remote ahead

    UpToDate --> [*]: Continue to shell

    UpdateAvailable --> Prompting: Show prompt
    Prompting --> Updating: User accepts
    Prompting --> Skipped: User declines

    Updating --> Updated: Success
    Updating --> Failed: Error

    Updated --> [*]: Continue to shell
    Skipped --> [*]: Continue to shell
    Failed --> [*]: Show error, continue
```

## Adding New Scheduled Tasks

1. Create a script in `cron/`:

```bash
#!/usr/bin/env bash
# cron/my-task.sh
LOG_FILE="${HOME}/.local/log/my-task.log"
echo "[$(date)] Running my task..." >> "$LOG_FILE"
# Your task here
```

2. Add entry to `cron/setup-cron.sh`:

```bash
CRON_JOBS=(
    "update.sh|0 9 * * 1|Weekly brew bundle (Monday 9am)"
    "backup.sh|0 2 * * 0|Weekly backup (Sunday 2am)"
    "my-task.sh|0 12 * * *|Daily task (noon)"  # New entry
)
```

3. Run setup:

```bash
dotfiles cron setup
```

## Troubleshooting

### Updates not running on login

Check that `.zlogin` is being executed:

```bash
# Verify the file exists
ls -la ~/.zlogin

# Check the update script is executable
ls -la ~/.local/share/chezmoi/tools/update.sh
```

### Cron jobs not running

```bash
# Check crontab entries
crontab -l

# Verify scripts are executable
ls -la ~/.local/share/chezmoi/cron/

# Re-run setup
dotfiles cron setup
```

### View cron logs

```bash
# Recent brew updates
dotfiles logs brew

# Recent backups
dotfiles logs backup

# Or directly
tail -50 ~/.local/log/brew-bundle.log
```

## Platform Support

| Feature | macOS | Linux | Windows |
|---------|-------|-------|---------|
| Interactive updates | Yes | Yes | No |
| Cron jobs | Yes | No* | No |
| Homebrew updates | Yes | Yes** | No |

\* Linux uses systemd timers (not implemented)
\** Linux Homebrew (Linuxbrew) supported

## Related Documentation

- [dotfiles update](commands/update.md) - Manual update command
- [dotfiles cron](commands/cron.md) - Cron management
- [dotfiles logs](commands/logs.md) - Log viewing
- [Bootstrap Guide](installation.md) - Initial setup
