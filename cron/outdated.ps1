#Requires -Version 5.1
<#
    outdated.ps1 - Daily outdated-package check (Windows)

    Windows counterpart of cron/outdated.sh, which only knows about Homebrew.
    Reports only; never installs anything.

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
$LogFile = Join-Path $LogDir 'outdated.log'

if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

function Log([string]$Message) {
    "[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message |
        Add-Content -Path $LogFile
}

Log "=== Checking for outdated packages ==="

$choco = Get-Command choco -ErrorAction SilentlyContinue | Select-Object -First 1
if ($choco) {
    Log "Checking Chocolatey packages..."
    # --limit-output gives 'name|current|available|pinned', one per line
    $rows = & $choco.Source outdated --limit-output 2>$null |
            Where-Object { $_ -match '\|' }

    if ($rows) {
        Log "Outdated packages ($(@($rows).Count)):"
        foreach ($row in $rows) {
            $f = $row -split '\|'
            Log ("  {0}: {1} -> {2}" -f $f[0], $f[1], $f[2])
        }
    } else {
        Log "All Chocolatey packages are up to date"
    }
} else {
    Log "Chocolatey not installed - skipping"
}

# Global npm packages, mirroring the sh version's extra checks
$npm = Get-Command npm -ErrorAction SilentlyContinue | Select-Object -First 1
if ($npm) {
    Log "Checking global npm packages..."
    $npmOut = & $npm.Source outdated -g --depth=0 2>$null
    if ($npmOut) {
        $npmOut | ForEach-Object { Log "  $_" }
    } else {
        Log "All global npm packages are up to date"
    }
}

Log "=== Outdated check finished ==="
