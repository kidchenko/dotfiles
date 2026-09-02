#Requires -Version 5.1
<#
    dotfiles.ps1 - CLI for managing dotfiles on Windows

    The Windows counterpart of tools/dotfiles (bash). It exposes the SAME
    commands, subcommands and flags - `dotfiles help` should read the same on
    both platforms - but runs the PowerShell implementations directly instead
    of detouring through git-bash.

    This file is a ROUTER. It deliberately contains no business logic: every
    command dispatches to the same per-OS scripts the bash CLI uses, so the two
    front ends cannot drift in behaviour. If you find yourself implementing
    something here, it belongs in a script under tools/ or cron/ instead.

    Pure PowerShell end to end: nothing here invokes bash. Enforced by
    tools/check-language-boundary.sh.

    Usage:
        dotfiles <command> [options]
        dotfiles help
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command = 'help',

    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    [string[]]$Arguments = @()
)

$ErrorActionPreference = 'Stop'

$VERSION = '1.0.0'

$DOTFILES_DIR = if ($env:XDG_DATA_HOME) {
    Join-Path $env:XDG_DATA_HOME 'chezmoi'
} else {
    Join-Path $HOME '.local\share\chezmoi'
}
$TOOLS_DIR = Join-Path $DOTFILES_DIR 'tools'

# Running from a clone rather than the chezmoi source directory
if (-not (Test-Path $TOOLS_DIR) -and $PSScriptRoot) {
    $TOOLS_DIR    = $PSScriptRoot
    $DOTFILES_DIR = Split-Path $PSScriptRoot -Parent
}
$CRON_DIR = Join-Path $DOTFILES_DIR 'cron'

function Say([string]$m)  { Write-Host "[dotfiles] $m" -ForegroundColor Green }
function Warn([string]$m) { Write-Host "[dotfiles] $m" -ForegroundColor Yellow }
function Fail([string]$m) { Write-Host "[dotfiles] ERROR: $m" -ForegroundColor Red; exit 1 }

function Test-Administrator {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    return (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-PowerShellExe {
    $pwsh = Get-Command pwsh -CommandType Application -ErrorAction SilentlyContinue |
            Select-Object -First 1
    if ($pwsh) { return $pwsh.Source }
    return (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe')
}

function Invoke-Ps1 {
    param(
        [string]$Path,
        [string[]]$Ps1Args = @(),
        [hashtable]$Ps1Params = @{}
    )
    if (-not (Test-Path $Path)) { Fail "Script not found: $Path" }

    # Named parameters and switches MUST go through $Ps1Params (a hashtable
    # splat). Array splatting passes elements POSITIONALLY, so @('-List') is
    # either silently dropped or rejected as a stray positional argument - it
    # never binds the -List switch.
    if ($Ps1Params.Count -gt 0 -and $Ps1Args.Count -gt 0) { & $Path @Ps1Params @Ps1Args }
    elseif ($Ps1Params.Count -gt 0) { & $Path @Ps1Params }
    elseif ($Ps1Args.Count -gt 0)   { & $Path @Ps1Args }
    else { & $Path }
}

# Translate bash-CLI style flags (--dry-run) into PowerShell switches
# (-DryRun) so the same invocation works on both platforms.
function ConvertTo-SwitchHash([string[]]$Tokens, [hashtable]$Map) {
    $h = @{}
    foreach ($t in $Tokens) {
        $key = $t.TrimStart('-').ToLower()
        if ($Map.ContainsKey($key)) { $h[$Map[$key]] = $true }
        else { Warn "Ignoring unknown option: $t" }
    }
    return $h
}

# Chocolatey needs administrator rights; without this `dotfiles packages`
# silently fails to write to the Chocolatey lib directory.
function Invoke-Ps1Elevated {
    param([string]$Path, [string[]]$Ps1Args = @(), [string]$Reason = '')

    if (-not (Test-Path $Path)) { Fail "Script not found: $Path" }

    if (Test-Administrator) {
        Invoke-Ps1 -Path $Path -Ps1Args $Ps1Args
        return
    }

    if ($Reason) { Say $Reason }
    Say "Requesting administrator rights - approve the UAC prompt..."

    $argList = @('-NoExit', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $Path)
    if ($Ps1Args.Count -gt 0) { $argList += $Ps1Args }

    try {
        Start-Process -FilePath (Get-PowerShellExe) -ArgumentList $argList -Verb RunAs | Out-Null
        Say "Continuing in the elevated window."
    } catch {
        Fail "Elevation declined. Re-run from an Administrator PowerShell."
    }
}

# Mirrors show_help in tools/dotfiles. Keep the two in sync.
function Show-Help {
    $C = 'Cyan'; $D = 'DarkGray'
    Write-Host "dotfiles v$VERSION - CLI for managing dotfiles"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  dotfiles <command> [options]"
    Write-Host ""
    Write-Host "Daily:"
    Write-Host "  update                   " -NoNewline -ForegroundColor $C; Write-Host "Pull and apply latest changes"
    Write-Host "  doctor                   " -NoNewline -ForegroundColor $C; Write-Host "Run health checks"
    Write-Host "      --quick              " -NoNewline -ForegroundColor $D; Write-Host "Skip slow checks (disk, outdated)"
    Write-Host "      --fix                " -NoNewline -ForegroundColor $D; Write-Host "Auto-fix issues"
    Write-Host "  status                   " -NoNewline -ForegroundColor $C; Write-Host "Show pending changes"
    Write-Host ""
    Write-Host "Packages:"
    Write-Host "  packages                 " -NoNewline -ForegroundColor $C; Write-Host "Manage all packages"
    Write-Host "      install              " -NoNewline -ForegroundColor $D; Write-Host "Install system packages (default)"
    Write-Host "      cleanup              " -NoNewline -ForegroundColor $D; Write-Host "Remove unlisted packages"
    Write-Host "      list                 " -NoNewline -ForegroundColor $D; Write-Host "Show installed packages"
    Write-Host "      outdated             " -NoNewline -ForegroundColor $D; Write-Host "Show packages with updates"
    Write-Host "      global               " -NoNewline -ForegroundColor $D; Write-Host "Install global tools (npm/pip/dotnet)"
    Write-Host "      extensions           " -NoNewline -ForegroundColor $D; Write-Host "Install extensions (vscode|browser|all)"
    Write-Host ""
    Write-Host "System:"
    Write-Host "  ssh                      " -NoNewline -ForegroundColor $C; Write-Host "Setup SSH keys with 1Password"
    Write-Host "      sync                 " -NoNewline -ForegroundColor $D; Write-Host "Auto-sync (used by setup)"
    Write-Host "      restore              " -NoNewline -ForegroundColor $D; Write-Host "Restore key from 1Password to ~/.ssh/"
    Write-Host "      generate             " -NoNewline -ForegroundColor $D; Write-Host "Generate new key in 1Password"
    Write-Host "      show                 " -NoNewline -ForegroundColor $D; Write-Host "Show local public key"
    Write-Host "      compare              " -NoNewline -ForegroundColor $D; Write-Host "Compare local key with 1Password"
    Write-Host "  defaults                 " -NoNewline -ForegroundColor $C; Write-Host "Apply Windows system defaults"
    Write-Host "  cron                     " -NoNewline -ForegroundColor $C; Write-Host "Manage scheduled tasks"
    Write-Host "      list                 " -NoNewline -ForegroundColor $D; Write-Host "List scheduled tasks (default)"
    Write-Host "      setup                " -NoNewline -ForegroundColor $D; Write-Host "Setup scheduled tasks"
    Write-Host "  logs                     " -NoNewline -ForegroundColor $C; Write-Host "View logs"
    Write-Host "      backup               " -NoNewline -ForegroundColor $D; Write-Host "View backup logs"
    Write-Host "      packages             " -NoNewline -ForegroundColor $D; Write-Host "View package install logs"
    Write-Host "  backup                   " -NoNewline -ForegroundColor $C; Write-Host "Backup project folders"
    Write-Host "      list                 " -NoNewline -ForegroundColor $D; Write-Host "List available backups"
    Write-Host "      restore              " -NoNewline -ForegroundColor $D; Write-Host "Restore from backup"
    Write-Host ""
    Write-Host "Lifecycle:"
    Write-Host "  setup                    " -NoNewline -ForegroundColor $C; Write-Host "Complete post-bootstrap setup"
    Write-Host "  bootstrap                " -NoNewline -ForegroundColor $C; Write-Host "Bootstrap on new machine"
    Write-Host "  destroy                  " -NoNewline -ForegroundColor $C; Write-Host "Remove dotfiles and state"
    Write-Host "      --all                " -NoNewline -ForegroundColor $D; Write-Host "Also remove chezmoi state, shell data"
    Write-Host "      --deep               " -NoNewline -ForegroundColor $D; Write-Host "Factory reset: remove all dev tools"
    Write-Host ""
    Write-Host "Utility:"
    Write-Host "  help                     " -NoNewline -ForegroundColor $C; Write-Host "Show this help message"
    Write-Host "  --version                " -NoNewline -ForegroundColor $C; Write-Host "Show version"
    Write-Host ""
}

# Run the declarative hooks around the package-install phase. A failing pre
# hook aborts; run-hooks.ps1 owns that policy, this just propagates it.
function Invoke-Hooks([string]$Phase) {
    $runner = Join-Path $TOOLS_DIR 'run-hooks.ps1'
    if (-not (Test-Path $runner)) { return }

    & $runner $Phase
    if ($LASTEXITCODE -ne 0 -and $Phase -eq 'pre_package_install') {
        Fail "Pre-install hooks failed - aborting"
    }
}

# --- Commands -------------------------------------------------------------

function Cmd-Update {
    Say "Updating dotfiles..."
    chezmoi update
    if ($LASTEXITCODE -ne 0) { Fail "chezmoi update failed" }
}

function Cmd-Status {
    Write-Host ""
    Write-Host "Dotfiles Changes"
    Write-Host ""

    $diff = chezmoi diff 2>$null
    if ($diff) {
        Write-Host "Pending dotfile changes:" -ForegroundColor Yellow
        $diff
    } else {
        Write-Host "No pending dotfile changes" -ForegroundColor Green
    }
    Write-Host ""

    if (Test-Path (Join-Path $DOTFILES_DIR '.git')) {
        Write-Host "Source repository:"
        git -C $DOTFILES_DIR status --short
        Write-Host ""
    }
}

function Cmd-Doctor([string[]]$A) {
    $switches = ConvertTo-SwitchHash $A @{ 'quick' = 'Quick'; 'fix' = 'Fix' }
    Invoke-Ps1 -Path (Join-Path $TOOLS_DIR 'doctor.ps1') -Ps1Params $switches
}

function Cmd-Packages([string[]]$A) {
    $sub  = if ($A.Count -gt 0) { $A[0] } else { 'install' }
    $rest = if ($A.Count -gt 1) { $A[1..($A.Count - 1)] } else { @() }

    switch ($sub) {
        'install' {
            Invoke-Hooks 'pre_package_install'
            Invoke-Ps1Elevated -Path (Join-Path $TOOLS_DIR 'os_installers\choco.ps1') `
                -Reason "Installing packages via Chocolatey (requires administrator)."
            Invoke-Hooks 'post_package_install'
        }
        'cleanup' {
            Warn "Chocolatey has no 'bundle cleanup' equivalent - nothing removed."
            Warn "Uninstall explicitly with: choco uninstall <package>"
        }
        'list'     { choco list }
        'outdated' { choco outdated }
        'global' {
            $sw = ConvertTo-SwitchHash $rest @{ 'dry-run' = 'DryRun'; 'dryrun' = 'DryRun' }
            Invoke-Ps1 -Path (Join-Path $TOOLS_DIR 'install-global-tools.ps1') -Ps1Params $sw
        }
        'extensions' {
            $target = if ($rest.Count -gt 0) { $rest[0] } else { 'all' }
            if ($target -in @('all', 'vscode')) {
                Invoke-Ps1 -Path (Join-Path $TOOLS_DIR 'install-vscode-extensions.ps1')
            }
            if ($target -in @('all', 'browser')) {
                Invoke-Ps1 -Path (Join-Path $TOOLS_DIR 'install-brave-extensions.ps1')
            }
        }
        default {
            Fail "Unknown packages subcommand: $sub (install|cleanup|list|outdated|global|extensions)"
        }
    }
}

function Cmd-Ssh([string[]]$A) {
    $sub = if ($A.Count -gt 0) { $A[0] } else { 'sync' }
    Invoke-Ps1 -Path (Join-Path $TOOLS_DIR 'setup-ssh-keys.ps1') -Ps1Args @($sub)
}

function Cmd-Defaults([string[]]$A) {
    $switches = ConvertTo-SwitchHash $A @{
        'dry-run'     = 'DryRun'
        'dryrun'      = 'DryRun'
        'skip-restart' = 'SkipRestart'
        'skiprestart' = 'SkipRestart'
    }
    Invoke-Ps1 -Path (Join-Path $TOOLS_DIR 'os_setup\windows-config.ps1') -Ps1Params $switches
}

function Cmd-Cron([string[]]$A) {
    # Default is 'list', matching the bash CLI - setup must be asked for.
    $sub = if ($A.Count -gt 0) { $A[0] } else { 'list' }
    $cronScript = Join-Path $TOOLS_DIR 'setup-cron.ps1'

    switch ($sub) {
        'list'   { Invoke-Ps1 -Path $cronScript -Ps1Params @{ List = $true } }
        'setup'  { Invoke-Ps1 -Path $cronScript }
        'remove' { Invoke-Ps1 -Path $cronScript -Ps1Params @{ Remove = $true } }
        default  { Fail "Unknown cron subcommand: $sub (list|setup)" }
    }
}

function Cmd-Logs([string[]]$A) {
    $logDir = if ($env:XDG_STATE_HOME) {
        Join-Path $env:XDG_STATE_HOME 'dotfiles'
    } else {
        Join-Path $HOME '.local\state\dotfiles'
    }

    if (-not (Test-Path $logDir)) { Say "No logs yet ($logDir)"; return }

    if ($A.Count -gt 0) {
        $needle = switch ($A[0]) {
            'packages' { 'choco-upgrade' }
            default    { $A[0] }
        }
        $match = Get-ChildItem $logDir -Filter "*$needle*.log" -ErrorAction SilentlyContinue |
                 Sort-Object LastWriteTime -Descending
        if (-not $match) { Fail "No log matching '$($A[0])' in $logDir" }
        Get-Content $match[0].FullName -Tail 200
        return
    }

    Write-Host ""
    Write-Host "Logs in $logDir"
    Get-ChildItem $logDir -Filter '*.log' -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object @{n='Log';e={$_.Name}},
                      @{n='Size';e={"{0:N1} KB" -f ($_.Length / 1KB)}},
                      LastWriteTime |
        Format-Table -AutoSize
    Write-Host "  dotfiles logs <name>   to tail one" -ForegroundColor DarkGray
    Write-Host ""
}

function Cmd-Backup([string[]]$A) {
    $sub = if ($A.Count -gt 0) { $A[0] } else { 'backup' }
    switch ($sub) {
        'backup' { Invoke-Ps1 -Path (Join-Path $TOOLS_DIR 'backup-projects.ps1') -Ps1Args @('backup') }
        'list' { Invoke-Ps1 -Path (Join-Path $TOOLS_DIR 'backup-projects.ps1') -Ps1Args @('list') }
        'restore' {
            Invoke-Ps1 -Path (Join-Path $TOOLS_DIR 'backup-projects.ps1') -Ps1Args @('restore')
        }
        default { Fail "Unknown backup subcommand: $sub (list|restore)" }
    }
}

function Cmd-Bootstrap([string[]]$A) {
    Invoke-Ps1 -Path (Join-Path $TOOLS_DIR 'bootstrap.ps1') -Ps1Args $A
}

function Cmd-Destroy([string[]]$A) {
    $sw = ConvertTo-SwitchHash $A @{ 'all' = 'All'; 'deep' = 'Deep'; 'dry-run' = 'DryRun'; 'yes' = 'Yes' }
    Invoke-Ps1 -Path (Join-Path $TOOLS_DIR 'destroy.ps1') -Ps1Params $sw
}

# Mirrors cmd_setup in the bash CLI, step numbering included. Packages come
# before ssh because the SSH step needs the 1Password CLI that packages
# installs.
function Cmd-Setup {
    Say "Running complete setup..."
    Write-Host ""

    Say "Step 1/6: Installing system packages..."
    try { Cmd-Packages @('install') } catch { Warn "Packages failed: $($_.Exception.Message)" }
    Write-Host ""

    Say "Step 2/6: Setting up SSH keys..."
    try { Cmd-Ssh @('sync') } catch { Warn "SSH setup failed: $($_.Exception.Message)" }
    Write-Host ""

    Say "Step 3/6: Installing global tools & extensions..."
    try { Cmd-Packages @('global') }     catch { Warn "Global tools failed: $($_.Exception.Message)" }
    try { Cmd-Packages @('extensions') } catch { Warn "Extensions failed: $($_.Exception.Message)" }
    Write-Host ""

    Say "Step 4/6: Setting up scheduled tasks..."
    try { Cmd-Cron @('setup') } catch { Warn "Cron setup failed: $($_.Exception.Message)" }
    Write-Host ""

    Say "Step 5/6: Applying system defaults..."
    try { Cmd-Defaults @() } catch { Warn "Defaults failed: $($_.Exception.Message)" }
    Write-Host ""

    Say "Setup complete!"
    Say "Run 'dotfiles doctor' to verify everything is configured correctly."
}

# --- Dispatch -------------------------------------------------------------

switch ($Command.ToLower()) {
    'update'     { Cmd-Update }
    'doctor'     { Cmd-Doctor    $Arguments }
    'status'     { Cmd-Status }
    'packages'   { Cmd-Packages  $Arguments }
    'ssh'        { Cmd-Ssh       $Arguments }
    'defaults'   { Cmd-Defaults  $Arguments }
    'cron'       { Cmd-Cron      $Arguments }
    'logs'       { Cmd-Logs      $Arguments }
    'backup'     { Cmd-Backup    $Arguments }
    'setup'      { Cmd-Setup }
    'bootstrap'  { Cmd-Bootstrap $Arguments }
    'destroy'    { Cmd-Destroy   $Arguments }
    'help'       { Show-Help }
    '--help'     { Show-Help }
    '-h'         { Show-Help }
    '--version'  { Write-Host "dotfiles v$VERSION" }
    '-v'         { Write-Host "dotfiles v$VERSION" }
    default {
        Warn "Unknown command: $Command"
        Show-Help
        exit 1
    }
}
