#Requires -Version 5.1
<#
.SYNOPSIS
    Bootstrap dotfiles on a new Windows machine.

.DESCRIPTION
    Windows counterpart of tools/bootstrap.sh.

    Unlike macOS (which ships git via the Xcode CLT and only needs Homebrew),
    a fresh Windows box has neither a package manager nor git. This script
    installs Chocolatey, then git, refreshing the session environment after
    each so the rest of the run can see them -- the equivalent of
    `eval "$(brew shellenv)"` in bootstrap.sh.

    Written for Windows PowerShell 5.1, the only shell guaranteed present on a
    fresh install. Do not use $IsWindows, ternaries, ?? or &&/|| in this file.

.PARAMETER DryRun
    Preview what would be installed without making changes.

.PARAMETER NoElevate
    Do not attempt to relaunch elevated; fail fast instead if not admin.

.EXAMPLE
    irm https://raw.githubusercontent.com/kidchenko/dotfiles/main/tools/bootstrap.ps1 | iex

.EXAMPLE
    & ([scriptblock]::Create((irm https://raw.githubusercontent.com/kidchenko/dotfiles/main/tools/bootstrap.ps1))) -DryRun
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$NoElevate,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

$DOTFILES_REPO = 'https://github.com/kidchenko/dotfiles.git'
$BOOTSTRAP_URL = 'https://raw.githubusercontent.com/kidchenko/dotfiles/main/tools/bootstrap.ps1'

# ---------------------------------------------------------------------------
# Output helpers (mirror say/warn/error in bootstrap.sh)
# ---------------------------------------------------------------------------

function Say([string]$Message) {
    Write-Host "[dotfiles] $Message" -ForegroundColor Green
}

function Warn([string]$Message) {
    Write-Host "[dotfiles] WARN: $Message" -ForegroundColor Yellow
}

function Fail([string]$Message) {
    Write-Host "[dotfiles] ERROR: $Message" -ForegroundColor Red
    exit 1
}

function Show-Help {
    Write-Host @'
Usage: bootstrap.ps1 [OPTIONS]

Bootstrap dotfiles on a new Windows machine.

Options:
  -DryRun       Preview what would be installed without making changes
  -NoElevate    Do not relaunch elevated; fail fast if not administrator
  -Help         Show this help message

Examples:
  .\bootstrap.ps1                # Full installation
  .\bootstrap.ps1 -DryRun        # Preview only

For more information, see: https://github.com/kidchenko/dotfiles
'@
}

# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------

function Enable-Tls12 {
    # Windows PowerShell 5.1 negotiates SSL3/TLS1.0 by default, which GitHub
    # and chocolatey.org both reject. Without this every download fails.
    try {
        [System.Net.ServicePointManager]::SecurityProtocol =
            [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    } catch {
        Warn "Could not raise TLS version: $($_.Exception.Message)"
    }
}

function Test-CommandExists([string]$Name) {
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    return ($null -ne $cmd)
}

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# The Windows equivalent of `eval "$(brew shellenv)"` in bootstrap.sh: make
# just-installed tools visible to this session without restarting the shell.
function Update-Environment {
    $chocoInstall = $env:ChocolateyInstall
    if ([string]::IsNullOrWhiteSpace($chocoInstall)) {
        $chocoInstall = Join-Path $env:ProgramData 'chocolatey'
    }

    $profileModule = Join-Path $chocoInstall 'helpers\chocolateyProfile.psm1'
    if (Test-Path $profileModule) {
        try {
            Import-Module $profileModule -Force -DisableNameChecking
            Update-SessionEnvironment
            return
        } catch {
            Warn "Update-SessionEnvironment failed, falling back: $($_.Exception.Message)"
        }
    }

    # Fallback: rebuild PATH from the registry by hand.
    $machinePath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    $parts = @()
    foreach ($p in @($machinePath, $userPath)) {
        if (-not [string]::IsNullOrWhiteSpace($p)) {
            $parts += $p.TrimEnd(';')
        }
    }
    $env:Path = ($parts -join ';')
}

function Invoke-Elevate {
    Say "Administrator rights are required to install Chocolatey and packages."
    Say "Relaunching elevated - approve the UAC prompt..."

    $inner = "[Net.ServicePointManager]::SecurityProtocol = " +
             "[Net.ServicePointManager]::SecurityProtocol -bor 3072; " +
             "& ([scriptblock]::Create((irm '$BOOTSTRAP_URL')))"
    if ($DryRun) {
        $inner = $inner + " -DryRun"
    }
    $inner = $inner + " -NoElevate"

    $argList = @('-NoExit', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', $inner)

    try {
        Start-Process -FilePath 'powershell.exe' -ArgumentList $argList -Verb RunAs | Out-Null
        Say "Bootstrap continues in the elevated window."
        exit 0
    } catch {
        Fail "Elevation was declined or failed. Re-run from an Administrator PowerShell."
    }
}

# ---------------------------------------------------------------------------
# Install steps
# ---------------------------------------------------------------------------

# Chocolatey is the Windows analogue of Homebrew (install_homebrew).
function Install-Chocolatey {
    if (Test-CommandExists 'choco') {
        Say "Chocolatey already installed: $((Get-Command choco).Source)"
        return
    }

    Say "Installing Chocolatey..."
    if ($DryRun) {
        Say "DRY-RUN: Would install Chocolatey from https://community.chocolatey.org"
        return
    }

    $prevPolicy = Get-ExecutionPolicy -Scope Process
    Set-ExecutionPolicy Bypass -Scope Process -Force
    try {
        Enable-Tls12
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString(
            'https://community.chocolatey.org/install.ps1'))
    } finally {
        Set-ExecutionPolicy $prevPolicy -Scope Process -Force -ErrorAction SilentlyContinue
    }

    Update-Environment

    if (-not (Test-CommandExists 'choco')) {
        Fail "Failed to install Chocolatey"
    }
    Say "Chocolatey installed successfully"
}

# macOS gets git for free from the Xcode CLT; Windows has to install it.
function Install-Git {
    if (Test-CommandExists 'git') {
        Say "git already installed: $((Get-Command git).Source)"
        return
    }

    Say "Installing git..."
    if ($DryRun) {
        Say "DRY-RUN: Would install git via Chocolatey"
        return
    }

    choco install git -y --no-progress --params "/GitAndUnixToolsOnPath /NoAutoCrlf"
    if ($LASTEXITCODE -ne 0) {
        Fail "Failed to install git (choco exit code $LASTEXITCODE)"
    }

    Update-Environment

    if (-not (Test-CommandExists 'git')) {
        Fail "git installed but not found on PATH. Restart your shell and re-run."
    }
    Say "git installed successfully"
}

function Install-Chezmoi {
    if (Test-CommandExists 'chezmoi') {
        Say "chezmoi already installed: $((Get-Command chezmoi).Source)"
        return
    }

    Say "Installing chezmoi..."
    if ($DryRun) {
        Say "DRY-RUN: Would install chezmoi via Chocolatey"
        return
    }

    choco install chezmoi -y --no-progress
    if ($LASTEXITCODE -ne 0) {
        Fail "Failed to install chezmoi (choco exit code $LASTEXITCODE)"
    }

    Update-Environment

    if (-not (Test-CommandExists 'chezmoi')) {
        Fail "chezmoi installed but not found on PATH. Restart your shell and re-run."
    }
    Say "chezmoi installed successfully"
}

function Invoke-ApplyDotfiles {
    Say "Initializing and applying dotfiles..."
    if ($DryRun) {
        Say "DRY-RUN: Would clone $DOTFILES_REPO and apply dotfiles via chezmoi"
        return
    }

    chezmoi init --apply $DOTFILES_REPO
    if ($LASTEXITCODE -ne 0) {
        Fail "chezmoi init --apply failed (exit code $LASTEXITCODE)"
    }
    Say "Dotfiles applied successfully!"
}

function Get-ChezmoiSourceDir {
    if (-not [string]::IsNullOrWhiteSpace($env:XDG_DATA_HOME)) {
        return (Join-Path $env:XDG_DATA_HOME 'chezmoi')
    }
    return (Join-Path $HOME '.local\share\chezmoi')
}

# Mirrors install_brew_packages: read the essential manifest from the chezmoi
# source dir, falling back to the local repo when run from a clone.
function Install-EssentialPackages {
    $sourceDir = Get-ChezmoiSourceDir
    $manifest = Join-Path $sourceDir 'packages.essential.config'

    if (-not (Test-Path $manifest)) {
        if ($PSScriptRoot) {
            $manifest = Join-Path (Split-Path $PSScriptRoot -Parent) 'packages.essential.config'
        }
    }

    if (-not (Test-Path $manifest)) {
        Say "Skipping essential packages (packages.essential.config not found)"
        return
    }

    Say "Installing essential Chocolatey packages..."
    if ($DryRun) {
        $count = @(([xml](Get-Content $manifest -Raw)).packages.package).Count
        Say "DRY-RUN: Would install $count packages from $manifest"
        return
    }

    choco install $manifest -y --no-progress
    if ($LASTEXITCODE -ne 0) {
        Warn "Some essential packages failed to install (choco exit code $LASTEXITCODE)"
    }

    Update-Environment
    Say "Essential packages installed (run 'dotfiles packages' for full installation)"
}

# Mirrors install_oh_my_zsh + install_zsh_plugins: the shell framework layer.
function Install-PowerShellModules {
    # This list is the union of what the shipped profile actually imports.
    # Pscx is required by ~/.config/powershell/modules.ps1 and z is the
    # directory jumper matching `brew "z"` on the macOS side - both were only
    # ever installed by the legacy psget.ps1, so dropping them here would leave
    # the profile importing modules nothing installs.
    $modules = @('posh-git', 'Terminal-Icons', 'PSReadLine', 'PSFzf', 'Pscx', 'z')

    Say "Installing PowerShell modules..."
    if ($DryRun) {
        Say "DRY-RUN: Would install PowerShell modules: $($modules -join ', ')"
        return
    }

    if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
        try {
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
        } catch {
            Warn "Failed to install NuGet provider: $($_.Exception.Message)"
            return
        }
    }

    try {
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
    } catch {
        Warn "Could not mark PSGallery trusted; installs may prompt."
    }

    foreach ($module in $modules) {
        if (Get-Module -ListAvailable -Name $module) {
            Say "PowerShell module $module already available"
            continue
        }
        try {
            Install-Module $module -Scope CurrentUser -Force -AllowClobber -SkipPublisherCheck -ErrorAction Stop
            Say "Installed PowerShell module: $module"
        } catch {
            Warn "Failed to install module ${module}: $($_.Exception.Message)"
        }
    }
}

# Mirrors setup_directories in bootstrap.sh, including reading the folder list
# from config.yaml. Hardcoding it here would drift from the bash side the first
# time backup.folders is edited.
function New-ProjectDirectories {
    $directories = @()

    $configFile = if ($env:XDG_CONFIG_HOME) {
        Join-Path $env:XDG_CONFIG_HOME 'dotfiles\config.yaml'
    } else {
        Join-Path $HOME '.config\dotfiles\config.yaml'
    }

    $yq = Get-Command yq -ErrorAction SilentlyContinue | Select-Object -First 1
    if ((Test-Path $configFile) -and $yq) {
        $directories = @(& $yq.Source -r '.backup.folders[]?' $configFile 2>$null |
                         Where-Object { $_ -and $_ -ne 'null' })
    }

    # Fallback when config has not been applied yet (fresh machine)
    if ($directories.Count -eq 0) {
        $directories = @(
            'kidchenko',
            'lambda3',
            'jetabroad',
            'thoughtworks',
            'sevenpeaks',
            'isho',
            'Documents\Screenshots'
        )
    }

    Say "Setting up project directories..."

    if ($DryRun) {
        Say "DRY-RUN: Would create directories:"
        foreach ($dir in $directories) {
            Say "  - $(Join-Path $HOME $dir)"
        }
        return
    }

    foreach ($dir in $directories) {
        $path = Join-Path $HOME $dir
        if (-not (Test-Path $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
            Say "Created $path"
        }
    }
    Say "Project directories ready"
}

# Mirrors setup_dotfiles_cli. Windows gets the native PowerShell CLI
# (tools/dotfiles.ps1), not a wrapper around the bash one - most commands
# dispatch to PowerShell implementations anyway, so routing through git-bash
# just to come back to PowerShell was a pointless round trip.
function Install-DotfilesCli {
    $sourceDir = Get-ChezmoiSourceDir
    $cliSource = Join-Path $sourceDir 'tools\dotfiles.ps1'
    $binDir = Join-Path $HOME '.local\bin'
    $cliTarget = Join-Path $binDir 'dotfiles.ps1'

    if (-not (Test-Path $cliSource)) {
        Say "Skipping dotfiles CLI (not found in source)"
        return
    }

    if ($DryRun) {
        Say "DRY-RUN: Would install dotfiles CLI at $cliTarget"
        return
    }

    if (-not (Test-Path $binDir)) {
        New-Item -ItemType Directory -Path $binDir -Force | Out-Null
    }

    # A forwarder rather than a copy, so `chezmoi update` picks up CLI changes
    # without re-running bootstrap. PowerShell resolves a bare `dotfiles` to
    # dotfiles.ps1 when its directory is on PATH.
    $shimLines = @(
        '# Auto-generated by tools/bootstrap.ps1 - forwards to the dotfiles CLI',
        '# in the chezmoi source directory so updates are picked up automatically.',
        "& '$cliSource' @args",
        'exit $LASTEXITCODE'
    )
    Set-Content -Path $cliTarget -Value $shimLines -Encoding UTF8

    # Ensure ~/.local/bin is on the user PATH for future sessions
    $userPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    if ($null -eq $userPath) {
        $userPath = ''
    }
    if ($userPath -notlike "*$binDir*") {
        $newPath = ($userPath.TrimEnd(';') + ';' + $binDir).TrimStart(';')
        [System.Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
        Say "Added $binDir to user PATH"
    }

    Say "dotfiles CLI installed (run 'dotfiles help' for usage)"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

function Main {
    if ($Help) {
        Show-Help
        return
    }

    Write-Host ""
    if ($DryRun) {
        Say "Starting dotfiles bootstrap (DRY-RUN MODE)..."
        Say "No changes will be made to your system."
    } else {
        Say "Starting dotfiles bootstrap..."
    }
    Write-Host ""

    Say "PowerShell $($PSVersionTable.PSVersion) on $([System.Environment]::OSVersion.VersionString)"

    Enable-Tls12

    # A dry run changes nothing, so it never needs elevation.
    if ((-not $DryRun) -and (-not (Test-Administrator))) {
        if ($NoElevate) {
            Fail "Administrator rights required. Re-run from an elevated PowerShell."
        }
        Invoke-Elevate
    }

    Install-Chocolatey
    Install-Git
    Install-Chezmoi
    Invoke-ApplyDotfiles
    Install-EssentialPackages
    Install-PowerShellModules
    New-ProjectDirectories
    Install-DotfilesCli

    Write-Host ""
    if ($DryRun) {
        Say "DRY-RUN complete!"
        Say "Run without -DryRun to perform actual installation."
    } else {
        Say "Bootstrap complete!"
        Say ""
        Say "Next steps:"
        Say "  1. Refresh this session:  refreshenv"
        Say "     (or just open a new PowerShell window)"
        Say "  2. Run complete setup:    dotfiles setup"
        Say "  3. Verify setup:          dotfiles doctor"
    }
    Write-Host ""
}

Main
