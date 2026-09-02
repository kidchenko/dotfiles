#Requires -Version 5.1
<#
    backup.ps1 - Weekly backup job (Windows)

    Windows counterpart of cron/backup.sh. Like the bash version, this is a thin
    scheduled-job wrapper: the real work lives in tools/backup-projects.ps1.

    Run by the Task Scheduler entry registered by tools/setup-cron.ps1.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'

$DOTFILES_DIR = if ($env:XDG_DATA_HOME) {
    Join-Path $env:XDG_DATA_HOME 'chezmoi'
} else {
    Join-Path $HOME '.local\share\chezmoi'
}
$BACKUP_SCRIPT = Join-Path $DOTFILES_DIR 'tools\backup-projects.ps1'

# Running from a clone rather than the chezmoi source directory
if (-not (Test-Path $BACKUP_SCRIPT) -and $PSScriptRoot) {
    $BACKUP_SCRIPT = Join-Path (Split-Path $PSScriptRoot -Parent) 'tools\backup-projects.ps1'
}

$LogDir = if ($env:XDG_STATE_HOME) {
    Join-Path $env:XDG_STATE_HOME 'dotfiles'
} else {
    Join-Path $HOME '.local\state\dotfiles'
}
$LogFile = Join-Path $LogDir 'backup-cron.log'

if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

function Log([string]$m) {
    "[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m | Add-Content -Path $LogFile
}

Log "=== Starting weekly backup ==="

# Distinguish "script is missing" from "backup ran and failed" - the bash side
# lacked this, which is how a wrong path went unnoticed for weeks.
if (-not (Test-Path $BACKUP_SCRIPT)) {
    Log "ERROR: Backup script not found at $BACKUP_SCRIPT"
    exit 1
}

& $BACKUP_SCRIPT backup

if ($LASTEXITCODE -eq 0) {
    Log "Backup completed successfully"
} else {
    Log "ERROR: Backup failed (exit $LASTEXITCODE)"
    exit 1
}

Log "=== Finished ==="
