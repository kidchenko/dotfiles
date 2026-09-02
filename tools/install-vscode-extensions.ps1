#Requires -Version 5.1
<#
.SYNOPSIS
    Install VS Code extensions from config.yaml (Windows).

.DESCRIPTION
    PowerShell counterpart of tools/install-vscode-extensions.sh. Reads the
    SAME extensions.vscode list from ~/.config/dotfiles/config.yaml - the
    extension IDs are shared, only the executor is per-platform.

.PARAMETER DryRun
    Preview without installing.

.PARAMETER Detailed
    Show already-installed extensions too.
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Detailed
)

$ErrorActionPreference = 'Continue'

$CONFIG_FILE = if ($env:XDG_CONFIG_HOME) {
    Join-Path $env:XDG_CONFIG_HOME 'dotfiles\config.yaml'
} else {
    Join-Path $HOME '.config\dotfiles\config.yaml'
}

function Say([string]$m)  { Write-Host "[vscode] $m" -ForegroundColor Green }
function Warn([string]$m) { Write-Host "[vscode] $m" -ForegroundColor Yellow }

# On Windows `code` is code.cmd - restricting to Application would miss it.
$code = Get-Command code -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $code) {
    Warn "VS Code CLI ('code') not found in PATH"
    Warn "Run 'Shell Command: Install code command in PATH' from VS Code"
    exit 0
}

$yq = Get-Command yq -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $yq) { Warn "yq not installed. Install with: choco install yq"; exit 1 }

if (-not (Test-Path $CONFIG_FILE)) {
    Warn "Config file not found: $CONFIG_FILE"
    Warn "Run 'chezmoi apply' to create it"
    exit 0
}

Say "Installing VS Code extensions..."

$wanted = @(& $yq.Source -r '.extensions.vscode[]?' $CONFIG_FILE 2>$null |
            Where-Object { $_ -and $_ -ne 'null' })

if ($wanted.Count -eq 0) {
    Say "No VS Code extensions defined in config.yaml"
    exit 0
}

# Extension IDs are case-insensitive; compare lowercased both ways.
$installedIds = @(& $code.Source --list-extensions 2>$null | ForEach-Object { $_.ToLower() })

$toInstall = @()
$skipped = 0
foreach ($ext in $wanted) {
    if ($installedIds -contains $ext.ToLower()) {
        if ($Detailed) { Write-Host "  = $ext (already installed)" -ForegroundColor DarkGray }
        $skipped++
        continue
    }
    if ($DryRun) { Write-Host "  -> Would install: $ext"; continue }
    $toInstall += $ext
}

$installed = 0
$failed = 0

if ($toInstall.Count -gt 0) {
    # One process for the whole batch, matching the sh version - VS Code start-up
    # dominates the cost, so per-extension invocations are dramatically slower.
    $cliArgs = @()
    foreach ($ext in $toInstall) { $cliArgs += @('--install-extension', $ext) }
    $cliArgs += '--force'

    Write-Host "  Installing $($toInstall.Count) extension(s)... " -NoNewline
    & $code.Source @cliArgs 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "ok" -ForegroundColor Green
        $installed = $toInstall.Count
    } else {
        Write-Host "failed" -ForegroundColor Red
        $failed = $toInstall.Count
    }
}

Write-Host ""
if ($DryRun) {
    Say "Dry run complete"
} else {
    Say "Done: $installed installed, $skipped skipped, $failed failed"
}
