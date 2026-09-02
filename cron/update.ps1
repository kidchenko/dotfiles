#Requires -Version 5.1
<#
    update.ps1 - Weekly package upgrade (Windows)

    Windows counterpart of cron/update.sh. That script is hardcoded to
    /opt/homebrew/bin/brew and exits 1 on any machine without Homebrew, so it
    can never do useful work here - this uses Chocolatey instead.

    Run by the Task Scheduler entry registered by tools/setup-cron.ps1.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'

$LogDir = if ($env:XDG_STATE_HOME) {
    Join-Path $env:XDG_STATE_HOME 'dotfiles'
} else {
    Join-Path $HOME '.local\state\dotfiles'
}
$LogFile = Join-Path $LogDir 'choco-upgrade.log'

if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

function Log([string]$Message) {
    "[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message |
        Add-Content -Path $LogFile
}

Log "=== Starting weekly package upgrade ==="

$choco = Get-Command choco -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $choco) {
    Log "ERROR: Chocolatey not found"
    exit 1
}

# Upgrading needs administrator. A scheduled task registered by a normal user
# runs unelevated, so say so plainly rather than failing with a raw ACL error.
$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Log "WARN: not elevated - Chocolatey cannot upgrade packages."
    Log "      Re-register this task with 'Run with highest privileges' to enable it."
    exit 0
}

$output = & $choco.Source upgrade all -y --no-progress 2>&1
$output | Add-Content -Path $LogFile

if ($LASTEXITCODE -eq 0) {
    Log "Package upgrade completed successfully"
} else {
    Log "ERROR: choco upgrade failed (exit $LASTEXITCODE)"
    exit 1
}

Log "=== Weekly package upgrade finished ==="
