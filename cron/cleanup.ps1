#Requires -Version 5.1
<#
    cleanup.ps1 - Weekly cache cleanup (Windows)

    Windows counterpart of cron/cleanup.sh, which cleans Homebrew caches.
    Trims the Chocolatey cache, the user TEMP directory and old dotfiles logs.

    Run by the Task Scheduler entry registered by tools/setup-cron.ps1.
#>
[CmdletBinding()]
param(
    [int]$LogRetentionDays = 30,
    [int]$TempRetentionDays = 7
)

$ErrorActionPreference = 'Continue'

$LogDir = if ($env:XDG_STATE_HOME) {
    Join-Path $env:XDG_STATE_HOME 'dotfiles'
} else {
    Join-Path $HOME '.local\state\dotfiles'
}
$LogFile = Join-Path $LogDir 'cleanup.log'

if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

function Log([string]$Message) {
    "[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message |
        Add-Content -Path $LogFile
}

function Get-SizeMB([string]$Path) {
    if (-not (Test-Path $Path)) { return 0 }
    $bytes = (Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue |
              Measure-Object -Property Length -Sum).Sum
    if (-not $bytes) { return 0 }
    return [math]::Round($bytes / 1MB, 1)
}

Log "=== Starting weekly cleanup ==="

# Chocolatey package cache
$chocoCache = Join-Path $env:TEMP 'chocolatey'
if (Test-Path $chocoCache) {
    $before = Get-SizeMB $chocoCache
    Remove-Item $chocoCache -Recurse -Force -ErrorAction SilentlyContinue
    Log "Cleared Chocolatey cache (${before} MB)"
} else {
    Log "No Chocolatey cache to clear"
}

# Stale files in TEMP. Only files older than the cutoff, and failures are
# ignored on purpose - anything still open by a running process stays put.
$cutoff = (Get-Date).AddDays(-$TempRetentionDays)
$stale = Get-ChildItem $env:TEMP -File -Force -ErrorAction SilentlyContinue |
         Where-Object { $_.LastWriteTime -lt $cutoff }
if ($stale) {
    $freed = [math]::Round((($stale | Measure-Object -Property Length -Sum).Sum) / 1MB, 1)
    $stale | Remove-Item -Force -ErrorAction SilentlyContinue
    Log "Removed $(@($stale).Count) stale temp file(s) (~${freed} MB)"
} else {
    Log "No stale temp files"
}

# Old dotfiles logs
$logCutoff = (Get-Date).AddDays(-$LogRetentionDays)
$oldLogs = Get-ChildItem $LogDir -File -Filter '*.log' -ErrorAction SilentlyContinue |
           Where-Object { $_.LastWriteTime -lt $logCutoff -and $_.FullName -ne $LogFile }
if ($oldLogs) {
    $oldLogs | Remove-Item -Force -ErrorAction SilentlyContinue
    Log "Removed $(@($oldLogs).Count) log file(s) older than $LogRetentionDays days"
}

Log "=== Weekly cleanup finished ==="
