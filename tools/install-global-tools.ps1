#Requires -Version 5.1
<#
.SYNOPSIS
    Install global npm/pip/dotnet tools from config.yaml (Windows).

.DESCRIPTION
    PowerShell counterpart of tools/install-global-tools.sh. Reads the SAME
    global_tools section of ~/.config/dotfiles/config.yaml - the package lists
    are shared, only the executor is per-platform.

.PARAMETER DryRun
    Preview without installing.
#>
[CmdletBinding()]
param([switch]$DryRun)

$ErrorActionPreference = 'Continue'

$CONFIG_FILE = if ($env:XDG_CONFIG_HOME) {
    Join-Path $env:XDG_CONFIG_HOME 'dotfiles\config.yaml'
} else {
    Join-Path $HOME '.config\dotfiles\config.yaml'
}

function NodeSay([string]$m)   { Write-Host "[node] $m"   -ForegroundColor Green }
function PythonSay([string]$m) { Write-Host "[python] $m" -ForegroundColor Blue }
function DotnetSay([string]$m) { Write-Host "[dotnet] $m" -ForegroundColor Cyan }
function Warn([string]$m)      { Write-Host "! $m"        -ForegroundColor Yellow }

$yq = Get-Command yq -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $yq) { Warn "yq not installed. Install with: choco install yq"; exit 1 }
if (-not (Test-Path $CONFIG_FILE)) { Warn "Config file not found: $CONFIG_FILE"; exit 1 }

function Get-List([string]$Path) {
    return @(& $yq.Source -r "$Path" $CONFIG_FILE 2>$null |
             Where-Object { $_ -and $_ -ne 'null' })
}

$npmPackages    = Get-List '.global_tools.npm[]?'
$pipPackages    = Get-List '.global_tools.pip[]?'
$dotnetPackages = Get-List '.global_tools.dotnet[]?'

$installed = 0
$failed    = @()

# --- Node -----------------------------------------------------------------

if ($npmPackages.Count -gt 0) {
    Write-Host ""
    NodeSay "Installing Node.js packages"
    Write-Host "  $($npmPackages -join ', ')" -ForegroundColor DarkGray

    $npm = Get-Command npm -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $npm) {
        Warn "npm not installed, skipping Node.js packages"
    } else {
        foreach ($pkg in $npmPackages) {
            if ($DryRun) { Write-Host "  -> Would install: $pkg"; continue }
            Write-Host "  installing $pkg..." -NoNewline
            & $npm.Source install -g $pkg --silent 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) { Write-Host " ok" -ForegroundColor Green; $installed++ }
            else { Write-Host " failed" -ForegroundColor Red; $failed += "npm:$pkg" }
        }
    }
}

# --- Python ---------------------------------------------------------------

if ($pipPackages.Count -gt 0) {
    Write-Host ""
    PythonSay "Installing Python packages"
    Write-Host "  $($pipPackages -join ', ')" -ForegroundColor DarkGray

    # Windows ships `pip` via the py launcher or Scripts dir; prefer pip3.
    $pip = Get-Command pip3 -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $pip) { $pip = Get-Command pip -ErrorAction SilentlyContinue | Select-Object -First 1 }

    if (-not $pip) {
        Warn "pip not installed, skipping Python packages"
    } else {
        foreach ($pkg in $pipPackages) {
            if ($DryRun) { Write-Host "  -> Would install: $pkg"; continue }
            Write-Host "  installing $pkg..." -NoNewline
            & $pip.Source install --user --quiet --upgrade $pkg 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) { Write-Host " ok" -ForegroundColor Green; $installed++ }
            else { Write-Host " failed" -ForegroundColor Red; $failed += "pip:$pkg" }
        }
    }
}

# --- .NET -----------------------------------------------------------------

if ($dotnetPackages.Count -gt 0) {
    Write-Host ""
    DotnetSay "Installing .NET tools"
    Write-Host "  $($dotnetPackages -join ', ')" -ForegroundColor DarkGray

    $dotnet = Get-Command dotnet -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $dotnet) {
        Warn "dotnet not installed, skipping .NET tools"
    } else {
        # `tool install` fails when the tool is already present, so list first
        # and use `tool update` for those - keeps re-runs idempotent.
        $existing = @()
        $listing = & $dotnet.Source tool list -g 2>$null
        foreach ($line in $listing) {
            if ($line -match '^(\S+)\s+\S+\s+\S+') { $existing += $matches[1].ToLower() }
        }

        foreach ($pkg in $dotnetPackages) {
            if ($DryRun) { Write-Host "  -> Would install: $pkg"; continue }
            $verb = if ($existing -contains $pkg.ToLower()) { 'update' } else { 'install' }
            Write-Host "  $verb $pkg..." -NoNewline
            & $dotnet.Source tool $verb -g $pkg 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) { Write-Host " ok" -ForegroundColor Green; $installed++ }
            else { Write-Host " failed" -ForegroundColor Red; $failed += "dotnet:$pkg" }
        }
    }
}

Write-Host ""
if ($DryRun) {
    Write-Host "Dry run complete" -ForegroundColor Green
} else {
    Write-Host "Done: $installed installed, $($failed.Count) failed" -ForegroundColor Green
    foreach ($f in $failed) { Warn "failed: $f" }
}
