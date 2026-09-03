#Requires -Version 5.1
<#
.SYNOPSIS
    Health checks for the dotfiles setup (Windows).

.DESCRIPTION
    Windows counterpart of tools/doctor.sh. This is NOT a port - the checks
    themselves are platform-specific (Chocolatey not Homebrew, PowerShell
    modules not oh-my-zsh, Task Scheduler not cron), so it mirrors the
    section structure and reporting while checking the right things.

.PARAMETER Quick
    Skip slow checks (disk space, outdated packages).

.PARAMETER Fix
    Attempt to fix issues automatically.
#>
[CmdletBinding()]
param(
    [switch]$Quick,
    [switch]$Fix
)

$ErrorActionPreference = 'Continue'

$script:Passed = 0
$script:Warned = 0
$script:Failed = 0

function Header([string]$t) {
    Write-Host ""
    Write-Host $t
    Write-Host ("-" * $t.Length) -ForegroundColor DarkGray
}
function Pass([string]$m) { Write-Host "  [ok]   $m" -ForegroundColor Green;      $script:Passed++ }
function Warn([string]$m) { Write-Host "  [warn] $m" -ForegroundColor Yellow;     $script:Warned++ }
function Fail([string]$m) { Write-Host "  [FAIL] $m" -ForegroundColor Red;        $script:Failed++ }
function Info([string]$m) { Write-Host "         $m" -ForegroundColor DarkGray }

function Find-Cmd([string]$n) {
    return (Get-Command $n -ErrorAction SilentlyContinue | Select-Object -First 1)
}

$CHEZMOI_SOURCE = if ($env:XDG_DATA_HOME) {
    Join-Path $env:XDG_DATA_HOME 'chezmoi'
} else {
    Join-Path $HOME '.local\share\chezmoi'
}
$CONFIG_HOME = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HOME '.config' }

Write-Host ""
Write-Host "Dotfiles Doctor (Windows)"

###############################################################################
Header "Core Tools"
###############################################################################

foreach ($t in @(
    @{ n = 'chezmoi'; req = $true },
    @{ n = 'git';     req = $true },
    @{ n = 'choco';   req = $true },
    @{ n = 'yq';      req = $true },
    @{ n = 'gh';      req = $false }
)) {
    $c = Find-Cmd $t.n
    if ($c) {
        $ver = try { (& $t.n --version 2>$null | Select-Object -First 1) } catch { '' }
        Pass "$($t.n) installed$(if ($ver) { " ($ver)" })"
    }
    elseif ($t.req) { Fail "$($t.n) not installed" }
    else { Warn "$($t.n) not installed (optional)" }
}

$psv = $PSVersionTable.PSVersion
if ($psv.Major -ge 7) { Pass "PowerShell $psv" }
else { Warn "PowerShell $psv - install PowerShell 7 (choco install powershell-core)" }

###############################################################################
Header "PowerShell Profile"
###############################################################################

if (Test-Path $PROFILE) {
    Pass "profile exists ($PROFILE)"
} else {
    Warn "profile missing ($PROFILE)"
    Info "Run: chezmoi apply"
}

$psConfig = Join-Path $CONFIG_HOME 'powershell'
foreach ($f in @('Microsoft.PowerShell_profile.ps1', 'login.ps1', 'modules.ps1', 'aliases.ps1')) {
    if (Test-Path (Join-Path $psConfig $f)) { Pass "$f present" }
    else { Warn "$f missing in $psConfig" }
}

foreach ($m in @('posh-git', 'Terminal-Icons', 'PSReadLine', 'PSFzf', 'Pscx', 'z')) {
    if (Get-Module -ListAvailable -Name $m) { Pass "module $m available" }
    else {
        Warn "module $m not installed"
        if ($Fix) {
            try {
                Install-Module $m -Scope CurrentUser -Force -AllowClobber -SkipPublisherCheck -ErrorAction Stop
                Info "Installed $m"
            } catch { Info "Could not install ${m}: $($_.Exception.Message)" }
        }
    }
}

###############################################################################
Header "1Password CLI"
###############################################################################

$op = Find-Cmd 'op'
if ($op) {
    Pass "1password-cli installed"
    $account = & $op.Source account list 2>$null
    if ($account) { Pass "1password-cli authenticated" }
    else { Warn "1password-cli not signed in (run: op signin)" }
} else {
    Warn "1password-cli not installed (optional, for secrets management)"
}

###############################################################################
Header "SSH Keys"
###############################################################################

$sshDir = Join-Path $HOME '.ssh'
if (Test-Path (Join-Path $sshDir 'id_ed25519')) { Pass "SSH key exists (~/.ssh/id_ed25519)" }
elseif (Test-Path (Join-Path $sshDir 'id_rsa'))  { Pass "SSH key exists (~/.ssh/id_rsa)" }
else { Warn "No SSH key found (run: dotfiles ssh)" }

if (Test-Path (Join-Path $sshDir 'config')) { Pass "SSH config exists" }
else { Warn "SSH config missing" }

###############################################################################
Header "XDG Directories"
###############################################################################

# Resolved up front: `if` is not usable as a value expression inside a
# hashtable literal, even though the file still parses.
$dataHome  = if ($env:XDG_DATA_HOME)  { $env:XDG_DATA_HOME }  else { Join-Path $HOME '.local\share' }
$cacheHome = if ($env:XDG_CACHE_HOME) { $env:XDG_CACHE_HOME } else { Join-Path $HOME '.cache' }

foreach ($d in @(
    @{ n = 'XDG_CONFIG_HOME'; p = $CONFIG_HOME },
    @{ n = 'XDG_DATA_HOME';   p = $dataHome },
    @{ n = 'XDG_CACHE_HOME';  p = $cacheHome },
    @{ n = 'XDG_BIN_HOME';    p = (Join-Path $HOME '.local\bin') }
)) {
    if (Test-Path $d.p) { Pass "$($d.n) exists ($($d.p))" }
    else {
        Warn "$($d.n) missing ($($d.p))"
        if ($Fix) { New-Item -ItemType Directory -Path $d.p -Force | Out-Null; Info "Created $($d.p)" }
    }
}

###############################################################################
Header "Chezmoi State"
###############################################################################

if (Test-Path $CHEZMOI_SOURCE) {
    Pass "chezmoi source directory exists"
    if (Find-Cmd 'chezmoi') {
        $diff = chezmoi diff 2>$null
        if ($diff) { Warn "dotfiles have pending changes (run: chezmoi diff)" }
        else { Pass "dotfiles in sync (no pending changes)" }
    }
} else {
    Fail "chezmoi source directory missing ($CHEZMOI_SOURCE)"
}

$cfg = Join-Path $CONFIG_HOME 'dotfiles\config.yaml'
if (Test-Path $cfg) { Pass "dotfiles config exists" }
else { Warn "dotfiles config missing ($cfg)" }

###############################################################################
Header "Git Configuration"
###############################################################################

if (Find-Cmd 'git') {
    foreach ($k in @('user.name', 'user.email')) {
        $v = git config --global $k 2>$null
        if ($v) { Pass "git $k set ($v)" } else { Warn "git $k not set" }
    }
    $lf = git config --global core.longpaths 2>$null
    if ($lf -eq 'true') { Pass "git core.longpaths enabled" }
    else {
        Warn "git core.longpaths not enabled - deep node_modules trees will fail"
        if ($Fix) { git config --global core.longpaths true; Info "Enabled core.longpaths" }
    }
}

###############################################################################
Header "Windows Configuration"
###############################################################################

$lp = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' `
       -Name 'LongPathsEnabled' -ErrorAction SilentlyContinue).LongPathsEnabled
if ($lp -eq 1) { Pass "LongPathsEnabled (paths over 260 chars allowed)" }
else {
    Warn "LongPathsEnabled not set - run 'dotfiles defaults' elevated"
}

$dev = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' `
        -Name 'AllowDevelopmentWithoutDevLicense' -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense
if ($dev -eq 1) { Pass "Developer Mode enabled (chezmoi can create symlinks)" }
else { Warn "Developer Mode off - chezmoi symlinks need elevation" }

###############################################################################
Header "Modern CLI Tools"
###############################################################################

foreach ($t in @('bat', 'fzf', 'jq', 'yq', 'lsd', 'rg', 'fd', 'delta', 'lazygit', 'nvim',
                 'btm', 'zoxide', 'dust', 'procs', 'sd', 'hyperfine', 'glow', 'tldr')) {
    if (Find-Cmd $t) { Pass "$t installed" } else { Warn "$t not installed" }
}

# gsudo is what makes elevation bearable - `gsudo choco upgrade all` instead of
# spawning a separate elevated window.
if (Find-Cmd 'gsudo') { Pass "gsudo installed (inline elevation)" }
else { Warn "gsudo not installed - elevation needs a separate window" }

###############################################################################
Header "Development Tools"
###############################################################################

foreach ($t in @('node', 'npm', 'dotnet', 'python', 'go', 'docker')) {
    if (Find-Cmd $t) { Pass "$t installed" } else { Warn "$t not installed" }
}

###############################################################################
Header "Scheduled Tasks"
###############################################################################

$tasks = Get-ScheduledTask -TaskPath '\dotfiles\' -ErrorAction SilentlyContinue
if ($tasks) {
    Pass "$(@($tasks).Count) dotfiles task(s) registered"
    foreach ($t in $tasks) {
        $i = Get-ScheduledTaskInfo -TaskName $t.TaskName -TaskPath '\dotfiles\' -ErrorAction SilentlyContinue
        if ($i -and $i.LastTaskResult -ne 0 -and $i.LastTaskResult -ne 267011) {
            Warn "$($t.TaskName) last run failed (result $($i.LastTaskResult))"
        }
    }
} else {
    Warn "No scheduled tasks registered (run: dotfiles cron setup)"
}

###############################################################################
if (-not $Quick) {
    Header "Disk Space"

    $drive = Get-PSDrive -Name ($HOME.Substring(0, 1)) -ErrorAction SilentlyContinue
    if ($drive) {
        $freeGB = [math]::Round($drive.Free / 1GB, 1)
        $totalGB = [math]::Round(($drive.Free + $drive.Used) / 1GB, 1)
        $pct = if ($totalGB -gt 0) { [math]::Round(($drive.Free / ($drive.Free + $drive.Used)) * 100) } else { 0 }
        if ($freeGB -lt 10) { Fail "Low disk space: ${freeGB} GB free of ${totalGB} GB ($pct%)" }
        elseif ($pct -lt 15) { Warn "Disk getting full: ${freeGB} GB free ($pct%)" }
        else { Pass "Disk space OK: ${freeGB} GB free of ${totalGB} GB ($pct%)" }
    }

    Header "Chocolatey Packages"

    if (Find-Cmd 'choco') {
        $outdated = @(choco outdated --limit-output 2>$null | Where-Object { $_ -match '\|' })
        if ($outdated.Count -eq 0) { Pass "All Chocolatey packages up to date" }
        else { Warn "$($outdated.Count) outdated package(s) - run: dotfiles packages outdated" }
    }
}

###############################################################################

Write-Host ""
Write-Host ("-" * 45) -ForegroundColor DarkGray
Write-Host "  $($script:Passed) passed, $($script:Warned) warnings, $($script:Failed) failed"
Write-Host ""

if ($script:Failed -gt 0) { exit 1 }
exit 0
