#Requires -Version 5.1
<#
.SYNOPSIS
    Open Brave extension install pages from config.yaml (Windows).

.DESCRIPTION
    PowerShell counterpart of tools/install-brave-extensions.sh, which has an
    explicit "Unsupported OS" branch on Windows and does nothing there.

    Behaviour matches the macOS path deliberately: already-installed extensions
    are detected and skipped, and the rest open in Brave for the user to click
    Add. Chromium gives no supported way to silently install a Web Store
    extension for an interactive profile.

    (There IS a machine-wide ExtensionInstallForcelist registry policy, but it
    requires administrator, force-installs behind the user's back, and makes
    the extension unremovable. That is not what the macOS script does, so it is
    deliberately not used here.)

.PARAMETER DryRun
    Preview without opening the browser.

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

$STORE_URL = 'https://chromewebstore.google.com/detail'

function Say([string]$m)  { Write-Host "[brave] $m" -ForegroundColor Green }
function Warn([string]$m) { Write-Host "[brave] $m" -ForegroundColor Yellow }

function Get-BraveExe {
    $candidates = @(
        (Join-Path $env:ProgramFiles 'BraveSoftware\Brave-Browser\Application\brave.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'BraveSoftware\Brave-Browser\Application\brave.exe'),
        (Join-Path $env:LOCALAPPDATA 'BraveSoftware\Brave-Browser\Application\brave.exe')
    )
    foreach ($c in $candidates) {
        if ($c -and (Test-Path $c)) { return $c }
    }
    return $null
}

# Mirrors is_extension_installed: scan every profile's Extensions directory.
function Test-ExtensionInstalled([string]$Id) {
    $base = Join-Path $env:LOCALAPPDATA 'BraveSoftware\Brave-Browser\User Data'
    if (-not (Test-Path $base)) { return $false }

    $profiles = Get-ChildItem $base -Directory -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -eq 'Default' -or $_.Name -like 'Profile*' }

    foreach ($p in $profiles) {
        if (Test-Path (Join-Path $p.FullName "Extensions\$Id")) { return $true }
    }
    return $false
}

$yq = Get-Command yq -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $yq) { Warn "yq not installed. Install with: choco install yq"; exit 1 }

if (-not (Test-Path $CONFIG_FILE)) {
    Warn "Config file not found: $CONFIG_FILE"
    Warn "Run 'chezmoi apply' to create it"
    exit 0
}

$wanted = @(& $yq.Source -r '.extensions.brave[]?' $CONFIG_FILE 2>$null |
            Where-Object { $_ -and $_ -ne 'null' })

if ($wanted.Count -eq 0) {
    Say "No Brave extensions defined in config.yaml"
    exit 0
}

$brave = Get-BraveExe
if (-not $brave -and -not $DryRun) {
    Warn "Brave not found - pages will open in your default browser."
}

$opened = 0
$skipped = 0

foreach ($id in $wanted) {
    if (Test-ExtensionInstalled $id) {
        if ($Detailed) { Write-Host "  = $id (already installed)" -ForegroundColor DarkGray }
        $skipped++
        continue
    }

    $url = "$STORE_URL/$id"

    if ($DryRun) {
        Write-Host "  -> Would open: $url"
        $opened++
        continue
    }

    try {
        if ($brave) { Start-Process -FilePath $brave -ArgumentList $url | Out-Null }
        else        { Start-Process $url | Out-Null }
        Write-Host "  opened $id"
        $opened++
    } catch {
        Warn "Could not open $url : $($_.Exception.Message)"
    }
}

Write-Host ""
if ($DryRun) {
    Say "Dry run complete ($opened would open, $skipped already installed)"
} else {
    Say "Done: $opened page(s) opened, $skipped already installed"
    if ($opened -gt 0) { Say "Click 'Add to Brave' on each page to finish." }
}
