#Requires -Version 5.1
<#
.SYNOPSIS
    Remove dotfiles and state (Windows).

.DESCRIPTION
    PowerShell counterpart of tools/destroy.sh. The paths are entirely
    different on Windows, so this is a parallel implementation rather than a
    port - but the flags, confirmation flow and staging behave identically.

    Everything is confirmed before removal, and a dry run is available. Nothing
    is deleted without the user typing the confirmation.

.PARAMETER All
    Also remove chezmoi state, PowerShell module data and shell history.

.PARAMETER Deep
    Factory reset: additionally remove dev tool caches (npm, NuGet, pip, Go).
    Implies -All.

.PARAMETER DryRun
    Show what would be removed without removing anything.

.PARAMETER Yes
    Skip the interactive confirmation. Use with care.
#>
[CmdletBinding()]
param(
    [switch]$All,
    [switch]$Deep,
    [switch]$DryRun,
    [switch]$Yes
)

$ErrorActionPreference = 'Continue'

if ($Deep) { $All = $true }

function Say([string]$m)  { Write-Host "[dotfiles] $m" -ForegroundColor Green }
function Warn([string]$m) { Write-Host "[dotfiles] $m" -ForegroundColor Yellow }

$CHEZMOI_SOURCE = if ($env:XDG_DATA_HOME) {
    Join-Path $env:XDG_DATA_HOME 'chezmoi'
} else {
    Join-Path $HOME '.local\share\chezmoi'
}
$CONFIG_HOME = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HOME '.config' }
$DATA_HOME   = if ($env:XDG_DATA_HOME)   { $env:XDG_DATA_HOME }   else { Join-Path $HOME '.local\share' }
$STATE_HOME  = if ($env:XDG_STATE_HOME)  { $env:XDG_STATE_HOME }  else { Join-Path $HOME '.local\state' }

# Managed dotfiles - always removed
$managed = @(
    (Join-Path $CONFIG_HOME 'powershell'),
    (Join-Path $CONFIG_HOME 'dotfiles'),
    (Join-Path $HOME 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'),
    (Join-Path $HOME 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1'),
    (Join-Path $HOME '.local\bin\dotfiles.ps1'),
    (Join-Path $HOME '.gitconfig')
)

# --all
$allDirs = @(
    $CHEZMOI_SOURCE,
    (Join-Path $CONFIG_HOME 'chezmoi'),
    (Join-Path $DATA_HOME 'chezmoi'),
    (Join-Path $STATE_HOME 'dotfiles')
)

# --deep
$deepDirs = @(
    (Join-Path $env:APPDATA 'npm'),
    (Join-Path $env:APPDATA 'npm-cache'),
    (Join-Path $HOME '.nuget\packages'),
    (Join-Path $HOME '.dotnet\tools'),
    (Join-Path $HOME 'go\pkg'),
    (Join-Path $env:LOCALAPPDATA 'pip\Cache')
)

function Show-Targets([string]$Title, [string[]]$Paths, [string]$Color = 'White') {
    $present = @($Paths | Where-Object { $_ -and (Test-Path $_) })
    if ($present.Count -eq 0) { return 0 }
    Write-Host ""
    Write-Host $Title -ForegroundColor $Color
    foreach ($p in $present) { Write-Host "    $p" }
    return $present.Count
}

function Remove-Targets([string[]]$Paths) {
    $removed = 0
    foreach ($p in $Paths) {
        if (-not $p -or -not (Test-Path $p)) { continue }
        if ($DryRun) { Write-Host "    would remove $p" -ForegroundColor DarkGray; $removed++; continue }
        try {
            Remove-Item $p -Recurse -Force -ErrorAction Stop
            Write-Host "    removed $p"
            $removed++
        } catch {
            Warn "could not remove $p : $($_.Exception.Message)"
        }
    }
    return $removed
}

Write-Host ""
Say "dotfiles destroy$(if ($DryRun) { ' (DRY RUN)' })"
if ($Deep)     { Warn "Mode: FACTORY RESET (--deep)" }
elseif ($All)  { Say  "Mode: Full cleanup (--all)" }
else           { Say  "Mode: Managed dotfiles only" }

$count = 0
$count += Show-Targets "The following managed files will be removed:" $managed
if ($All)  { $count += Show-Targets "Additional directories (--all):" $allDirs 'Yellow' }
if ($Deep) {
    $count += Show-Targets "Deep clean directories (--deep):" $deepDirs 'Red'
    Warn "This removes dev tool caches - npm, NuGet, pip, Go."
}

if ($count -eq 0) { Write-Host ""; Say "Nothing to remove."; exit 0 }

Write-Host ""
if (-not $DryRun -and -not $Yes) {
    $confirm = Read-Host "Type 'yes' to remove the $count item(s) listed above"
    if ($confirm -ne 'yes') { Say "Aborted - nothing removed."; exit 0 }
}

$removed = 0
$removed += Remove-Targets $managed
if ($All)  { $removed += Remove-Targets $allDirs }
if ($Deep) { $removed += Remove-Targets $deepDirs }

Write-Host ""
if ($DryRun) {
    Say "Dry run complete - $removed item(s) would be removed."
} else {
    Say "Removed $removed item(s)."
    Say "Chocolatey packages were left alone. Remove them with: choco uninstall <package>"
}
Write-Host ""
