#Requires -Version 5.1
<#
.SYNOPSIS
    Run declarative package-install hooks from config.yaml (Windows).

.DESCRIPTION
    PowerShell twin of tools/run-hooks.sh. Same config, same tools/hooks/
    directory, same rules - but it only ever executes .ps1 hooks, exactly as
    the bash runner only ever executes .sh hooks. Neither invokes the other's
    interpreter.

    Hooks are declared in ~/.config/dotfiles/config.yaml as a plain list of
    script NAMES - no paths, no inline commands:

      hooks:
        enabled: true
        pre_package_install:
          - check-disk-space
        post_package_install:
          - notify-done

    Resolution
      A name resolves inside tools/hooks/ and nowhere else. The file extension
      encodes the OS, so one config works on every platform:

        foo.ps1  -> runs here (Windows)
        foo.sh   -> runs under run-hooks.sh (macOS/Linux)

      A listed name with only a .sh implementation is skipped. A name that
      resolves nowhere is a typo, and is a hard error.

    Convention
      tools/hooks/packages.custom.ps1 runs at post_package_install even when it
      is not listed. It is optional - absence is not an error.

    Failure semantics
      pre  hook fails -> abort (it is a precondition)
      post hook fails -> warn and continue (it is a follow-up)

    Hooks re-run on every `dotfiles packages`, including the scheduled weekly
    job, so they MUST be idempotent.

.PARAMETER Phase
    pre_package_install or post_package_install.
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateSet('pre_package_install', 'post_package_install')]
    [string]$Phase
)

$ErrorActionPreference = 'Continue'

$DOTFILES_DIR = if ($env:XDG_DATA_HOME) {
    Join-Path $env:XDG_DATA_HOME 'chezmoi'
} else {
    Join-Path $HOME '.local\share\chezmoi'
}
$HOOKS_DIR = Join-Path $DOTFILES_DIR 'tools\hooks'

# Running from a clone rather than the chezmoi source directory
if (-not (Test-Path $HOOKS_DIR) -and $PSScriptRoot) {
    $HOOKS_DIR = Join-Path $PSScriptRoot 'hooks'
}

$CONFIG_FILE = if ($env:XDG_CONFIG_HOME) {
    Join-Path $env:XDG_CONFIG_HOME 'dotfiles\config.yaml'
} else {
    Join-Path $HOME '.config\dotfiles\config.yaml'
}

function Say([string]$m)  { Write-Host "[hooks] $m" -ForegroundColor Green }
function Warn([string]$m) { Write-Host "[hooks] WARN: $m" -ForegroundColor Yellow }
function Fail([string]$m) { Write-Host "[hooks] ERROR: $m" -ForegroundColor Red; exit 1 }

# Names are keys, not paths. Reject anything that could escape HOOKS_DIR.
function Test-HookName([string]$Name) {
    if ($Name -match '[\\/]' -or $Name -match '\.\.') {
        Fail "Invalid hook name '$Name' - names must not contain path separators or '..'"
    }
}

# Returns the .ps1 path, '' when the hook is implemented only for the other
# platform, or $null when it resolves nowhere at all.
function Resolve-Hook([string]$Name) {
    $ps1 = Join-Path $HOOKS_DIR "$Name.ps1"
    if (Test-Path $ps1) { return $ps1 }
    if (Test-Path (Join-Path $HOOKS_DIR "$Name.sh")) { return '' }
    return $null
}

# --- Gather the hook list -------------------------------------------------

$hooks = @()

if (Test-Path $CONFIG_FILE) {
    $yq = Get-Command yq -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($yq) {
        # Raw read, not `// true`: yq's alternative operator treats `false` as
        # empty, so `.enabled // true` returns true for `enabled: false` and
        # the kill switch silently stops working.
        $enabled = & $yq.Source -r '.hooks.enabled' $CONFIG_FILE 2>$null
        if ($enabled -eq 'false') {
            Say "Hooks disabled in config - skipping $Phase"
            exit 0
        }
        $hooks = @(& $yq.Source -r ".hooks.$Phase[]?" $CONFIG_FILE 2>$null |
                   Where-Object { $_ -and $_ -ne 'null' })
    } else {
        Warn "yq not installed - cannot read hooks from config"
    }
}

# Convention: packages.custom runs post-install whether listed or not.
# Dedupe so listing it explicitly does not run it twice.
if ($Phase -eq 'post_package_install' -and $hooks -notcontains 'packages.custom') {
    if ((Test-Path (Join-Path $HOOKS_DIR 'packages.custom.ps1')) -or
        (Test-Path (Join-Path $HOOKS_DIR 'packages.custom.sh'))) {
        $hooks += 'packages.custom'
    }
}

if ($hooks.Count -eq 0) { exit 0 }

# --- Run them in declared order -------------------------------------------

Say "Running $Phase hooks ($($hooks.Count))..."

foreach ($name in $hooks) {
    Test-HookName $name

    $path = Resolve-Hook $name
    if ($null -eq $path) {
        Fail "Hook '$name' not found in $HOOKS_DIR (expected $name.ps1 or $name.sh)"
    }
    if ($path -eq '') {
        Write-Host "  skip $name (targets another OS)" -ForegroundColor DarkGray
        continue
    }

    Say "-> $name"

    $failed = $false
    try {
        & $path
        if ($LASTEXITCODE -ne 0 -and $null -ne $LASTEXITCODE) { $failed = $true }
    } catch {
        Warn $_.Exception.Message
        $failed = $true
    }

    if (-not $failed) { continue }

    # pre hooks are preconditions; post hooks are follow-ups
    if ($Phase -eq 'pre_package_install') {
        Fail "Pre-install hook '$name' failed - aborting package install"
    } else {
        Warn "Post-install hook '$name' failed - continuing"
    }
}

Say "$Phase hooks complete"
