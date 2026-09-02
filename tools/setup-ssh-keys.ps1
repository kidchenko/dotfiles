#Requires -Version 5.1
<#
.SYNOPSIS
    Manage SSH keys stored in 1Password (Windows).

.DESCRIPTION
    PowerShell counterpart of tools/setup-ssh-keys.sh. Reads the SAME ssh:
    section of ~/.config/dotfiles/config.yaml (vault, item_name, key_type) and
    drives the same `op` CLI, which is itself cross-platform - only the file
    permission handling differs, because Windows uses ACLs rather than chmod.

.PARAMETER Command
    sync (default), restore, generate, show, or compare.
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('sync', 'restore', 'generate', 'show', 'compare', 'help')]
    [string]$Command = 'sync'
)

$ErrorActionPreference = 'Continue'

$CONFIG_FILE = if ($env:XDG_CONFIG_HOME) {
    Join-Path $env:XDG_CONFIG_HOME 'dotfiles\config.yaml'
} else {
    Join-Path $HOME '.config\dotfiles\config.yaml'
}

$SSH_DIR          = Join-Path $HOME '.ssh'
$VAULT            = 'development'
$KEY_NAME         = 'SSH Key'
$KEY_TYPE         = 'ed25519'

function Say([string]$m)  { Write-Host "[ssh] $m" -ForegroundColor Green }
function Warn([string]$m) { Write-Host "[ssh] $m" -ForegroundColor Yellow }
function Info([string]$m) { Write-Host "      $m" -ForegroundColor DarkGray }
function Fail([string]$m) { Write-Host "[ssh] ERROR: $m" -ForegroundColor Red; exit 1 }

# --- Config ---------------------------------------------------------------

$yq = Get-Command yq -ErrorAction SilentlyContinue | Select-Object -First 1
if ($yq -and (Test-Path $CONFIG_FILE)) {
    $v = & $yq.Source -r '.ssh.vault' $CONFIG_FILE 2>$null
    if ($v -and $v -ne 'null') { $VAULT = $v }
    $v = & $yq.Source -r '.ssh.item_name' $CONFIG_FILE 2>$null
    if ($v -and $v -ne 'null') { $KEY_NAME = $v }
    $v = & $yq.Source -r '.ssh.key_type' $CONFIG_FILE 2>$null
    if ($v -and $v -ne 'null') { $KEY_TYPE = $v }
}

$PRIVATE_KEY_FILE = Join-Path $SSH_DIR "id_$KEY_TYPE"
$PUBLIC_KEY_FILE  = "$PRIVATE_KEY_FILE.pub"

# --- Helpers --------------------------------------------------------------

function Get-Op {
    $op = Get-Command op -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $op) { Fail "1Password CLI (op) not installed. Run: choco install 1password-cli" }
    & $op.Source account list 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { Fail "Not signed in to 1Password. Run: op signin" }
    return $op.Source
}

function Test-KeyInVault([string]$Op) {
    & $Op item get $KEY_NAME --vault $VAULT 2>&1 | Out-Null
    return ($LASTEXITCODE -eq 0)
}

function Test-KeyLocal { return (Test-Path $PRIVATE_KEY_FILE) }

# Windows has no chmod. A private key must not be readable by other users, so
# strip inheritance and grant the current user alone - the ACL equivalent of
# chmod 600. OpenSSH on Windows refuses keys with looser permissions.
function Protect-KeyFile([string]$Path) {
    try {
        $acl = Get-Acl $Path
        $acl.SetAccessRuleProtection($true, $false)   # disable inheritance, drop inherited
        foreach ($rule in @($acl.Access)) { [void]$acl.RemoveAccessRule($rule) }
        $me = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
            $me, 'FullControl', 'None', 'None', 'Allow')))
        Set-Acl -Path $Path -AclObject $acl
    } catch {
        Warn "Could not tighten permissions on $Path : $($_.Exception.Message)"
    }
}

function New-SshDir {
    if (-not (Test-Path $SSH_DIR)) { New-Item -ItemType Directory -Path $SSH_DIR -Force | Out-Null }
}

# --- Commands -------------------------------------------------------------

function Cmd-Restore {
    $op = Get-Op
    if (-not (Test-KeyInVault $op)) {
        Fail "SSH key '$KEY_NAME' not found in 1Password vault '$VAULT'. Run 'dotfiles ssh generate' first."
    }

    if (Test-KeyLocal) {
        Warn "SSH key already exists at $PRIVATE_KEY_FILE"
        $confirm = Read-Host "Overwrite local key? [y/N]"
        if ($confirm -notmatch '^[Yy]$') { Say "Aborted"; exit 0 }
    }

    Say "Restoring SSH key from 1Password..."
    New-SshDir

    & $op read "op://$VAULT/$KEY_NAME/private_key" | Set-Content -Path $PRIVATE_KEY_FILE -NoNewline
    if ($LASTEXITCODE -ne 0) { Fail "Failed to read private key from 1Password" }
    Protect-KeyFile $PRIVATE_KEY_FILE

    & $op read "op://$VAULT/$KEY_NAME/public_key" | Set-Content -Path $PUBLIC_KEY_FILE -NoNewline

    Say "SSH key restored to $SSH_DIR"
    Write-Host ""
    Info "Public key:"
    Get-Content $PUBLIC_KEY_FILE
    Write-Host ""
}

function Cmd-Generate {
    $op = Get-Op

    if (Test-KeyInVault $op) {
        Warn "SSH key '$KEY_NAME' already exists in vault '$VAULT'"
        $confirm = Read-Host "Replace it? This cannot be undone [y/N]"
        if ($confirm -notmatch '^[Yy]$') { Say "Aborted"; exit 0 }
        & $op item delete $KEY_NAME --vault $VAULT
    }

    Say "Generating a new $KEY_TYPE key in 1Password..."
    & $op item create --category "SSH Key" --title $KEY_NAME --vault $VAULT `
        --ssh-generate-key $KEY_TYPE
    if ($LASTEXITCODE -ne 0) { Fail "Failed to create the SSH key in 1Password" }

    Say "Key created. Restoring it locally..."
    Cmd-Restore
}

function Cmd-Show {
    if (-not (Test-KeyLocal)) { Fail "No local key at $PRIVATE_KEY_FILE. Run 'dotfiles ssh restore'." }
    if (-not (Test-Path $PUBLIC_KEY_FILE)) { Fail "No public key at $PUBLIC_KEY_FILE" }
    Get-Content $PUBLIC_KEY_FILE
}

function Cmd-Compare {
    $op = Get-Op
    $hasLocal = Test-KeyLocal
    $hasVault = Test-KeyInVault $op

    if ($hasLocal -and $hasVault) {
        $localPub  = (Get-Content $PUBLIC_KEY_FILE -Raw).Trim()
        $vaultPub  = (& $op read "op://$VAULT/$KEY_NAME/public_key" | Out-String).Trim()
        if ($localPub -eq $vaultPub) { Say "Local key matches 1Password" }
        else {
            Warn "Local key DIFFERS from 1Password"
            Info "local:     $localPub"
            Info "1Password: $vaultPub"
        }
    }
    elseif ($hasVault) { Warn "Key exists in 1Password but not locally (run: dotfiles ssh restore)" }
    elseif ($hasLocal) { Warn "Key exists locally but not in 1Password (run: dotfiles ssh generate)" }
    else               { Warn "No key locally or in 1Password (run: dotfiles ssh generate)" }
}

# Restore if missing, otherwise only report a mismatch. Never overwrites
# silently - matching the sh version's sync semantics.
function Cmd-Sync {
    $op = Get-Op
    $hasLocal = Test-KeyLocal
    $hasVault = Test-KeyInVault $op

    if (-not $hasVault) {
        Warn "No SSH key in 1Password vault '$VAULT' (run: dotfiles ssh generate)"
        return
    }
    if (-not $hasLocal) { Say "Local key missing - restoring from 1Password"; Cmd-Restore; return }
    Cmd-Compare
}

switch ($Command) {
    'sync'     { Cmd-Sync }
    'restore'  { Cmd-Restore }
    'generate' { Cmd-Generate }
    'show'     { Cmd-Show }
    'compare'  { Cmd-Compare }
    'help' {
        Write-Host "Usage: dotfiles ssh [sync|restore|generate|show|compare]"
    }
}
