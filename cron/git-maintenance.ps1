#Requires -Version 5.1
<#
    git-maintenance.ps1 - Weekly git maintenance (Windows)

    Windows counterpart of cron/git-maintenance.sh. Runs `git gc` across the
    chezmoi source and the project directories. git.exe is a normal Windows
    executable, so this needs no shell of any kind.

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
$LogFile = Join-Path $LogDir 'git-maintenance.log'

$ChezmoiDir = if ($env:XDG_DATA_HOME) {
    Join-Path $env:XDG_DATA_HOME 'chezmoi'
} else {
    Join-Path $HOME '.local\share\chezmoi'
}

$ProjectDirs = @(
    (Join-Path $HOME 'kidchenko'),
    (Join-Path $HOME 'lambda3'),
    (Join-Path $HOME 'jetabroad')
)

if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

function Log([string]$Message) {
    "[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message |
        Add-Content -Path $LogFile
}

function Invoke-RepoMaintenance {
    param([string]$Repo)

    if (-not (Test-Path (Join-Path $Repo '.git'))) { return }

    $name = Split-Path $Repo -Leaf
    Log "Maintaining $name..."

    $out = & $git.Source -C $Repo gc --auto --quiet 2>&1
    if ($LASTEXITCODE -eq 0) {
        Log "  $name : ok"
    } else {
        Log "  $name : FAILED (exit $LASTEXITCODE)"
        $out | ForEach-Object { Log "    $_" }
    }
}

Log "=== Starting weekly git maintenance ==="

$git = Get-Command git -CommandType Application -ErrorAction SilentlyContinue |
       Select-Object -First 1
if (-not $git) {
    Log "ERROR: git not found"
    exit 1
}

Invoke-RepoMaintenance -Repo $ChezmoiDir

foreach ($dir in $ProjectDirs) {
    if (-not (Test-Path $dir)) {
        Log "Directory not found: $dir"
        continue
    }
    Log "Scanning: $dir"
    # One level deep, matching the sh version: these are containers of repos,
    # not repos themselves, and going deeper would hit nested repos.
    Get-ChildItem $dir -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        Invoke-RepoMaintenance -Repo $_.FullName
    }
}

Log "=== Weekly git maintenance finished ==="
