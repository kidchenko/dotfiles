#Requires -Version 5.1
<#
.SYNOPSIS
    Windows configuration script - the counterpart to os_setup/macos-config.sh.

.DESCRIPTION
    Run once on a fresh Windows install to configure system preferences for
    development: productivity, privacy, performance and security hardening.

    Design rules for anything added here:

      * Idempotent. Every run must converge on the same state.
      * Reversible. Registry values only; nothing uninstalled or deleted.
      * Never weakens security. This script does NOT disable Defender,
        SmartScreen, UAC or Windows Update - those exist for good reasons and
        turning them off to "speed things up" is how machines get owned. It
        only hardens (see the Security section).
      * HKCU by default. Machine-wide (HKLM) changes are grouped and skipped
        with a warning when not elevated, so the useful 80% still applies
        without administrator rights.

    A sign-out or `Restart-Explorer` is needed for some Explorer/taskbar
    settings to take effect.

.PARAMETER DryRun
    Print every change without writing anything.

.PARAMETER SkipRestart
    Do not restart Explorer at the end.

.EXAMPLE
    dotfiles defaults

.EXAMPLE
    pwsh -File tools/os_setup/windows-config.ps1 -DryRun
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$SkipRestart
)

$ErrorActionPreference = 'Stop'

$script:Applied = 0
$script:Skipped = 0

function Say([string]$m)  { Write-Host "[windows-config] $m" -ForegroundColor Green }
function Note([string]$m) { Write-Host "    $m" -ForegroundColor DarkGray }
function Warn([string]$m) { Write-Host "[windows-config] $m" -ForegroundColor Yellow }

function Test-Administrator {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    return (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

$IsElevated = Test-Administrator

# Core primitive: set one registry value, idempotently.
function Set-RegValue {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)]$Value,
        [ValidateSet('DWord', 'String', 'ExpandString', 'QWord', 'Binary')]
        [string]$Type = 'DWord',
        [string]$Because = ''
    )

    # HKLM needs elevation; skip rather than blow up mid-run.
    if ($Path -like 'HKLM:*' -and -not $IsElevated) {
        Note "skip (needs admin): $Name"
        $script:Skipped++
        return
    }

    try {
        $current = $null
        if (Test-Path $Path) {
            $existing = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
            if ($existing) { $current = $existing.$Name }
        }

        if ($null -ne $current -and $current -eq $Value) {
            return   # already correct - stay quiet
        }

        if ($DryRun) {
            Note "would set $Name = $Value  ($Because)"
            $script:Applied++
            return
        }

        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        New-ItemProperty -Path $Path -Name $Name -Value $Value `
            -PropertyType $Type -Force | Out-Null

        Note "$Name = $Value  ($Because)"
        $script:Applied++
    } catch {
        Warn "failed to set $Name at $Path : $($_.Exception.Message)"
        $script:Skipped++
    }
}

$Explorer  = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
$Search    = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'
$ContentD  = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
$AdvertId  = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo'

Write-Host ""
Say "Configuring Windows$(if ($DryRun) { ' (DRY RUN - no changes)' })"
if (-not $IsElevated) {
    Warn "Not elevated - machine-wide settings will be skipped."
    Warn "Re-run from an Administrator shell to apply everything."
}
Write-Host ""

###############################################################################
# Explorer - make it usable for development                                   #
###############################################################################
Say "Explorer"

Set-RegValue -Path $Explorer -Name 'HideFileExt' -Value 0 `
    -Because 'always show file extensions - hiding them is a phishing vector'

Set-RegValue -Path $Explorer -Name 'Hidden' -Value 1 `
    -Because 'show hidden files (.gitignore, .env)'

Set-RegValue -Path $Explorer -Name 'ShowSuperHidden' -Value 0 `
    -Because 'but keep protected OS files hidden'

Set-RegValue -Path $Explorer -Name 'LaunchTo' -Value 1 `
    -Because 'open Explorer to This PC, not Quick Access'

Set-RegValue -Path $Explorer -Name 'NavPaneShowAllFolders' -Value 1 `
    -Because 'show the full folder tree in the nav pane'

Set-RegValue -Path $Explorer -Name 'SeparateProcess' -Value 1 `
    -Because 'each window in its own process - one hang stops killing them all'

###############################################################################
# Taskbar and Start - remove the noise                                        #
###############################################################################
Say "Taskbar and Start"

Set-RegValue -Path $Explorer -Name 'ShowTaskViewButton' -Value 0 `
    -Because 'hide Task View button (Win+Tab still works)'

Set-RegValue -Path $Explorer -Name 'TaskbarDa' -Value 0 `
    -Because 'remove Widgets / news and interests'

Set-RegValue -Path $Explorer -Name 'TaskbarMn' -Value 0 `
    -Because 'remove Chat / Meet Now'

Set-RegValue -Path $Search -Name 'SearchboxTaskbarMode' -Value 1 `
    -Because 'collapse the search box to an icon'

Set-RegValue -Path $Search -Name 'BingSearchEnabled' -Value 0 `
    -Because 'Start menu searches the machine, not the web'

Set-RegValue -Path $Search -Name 'CortanaConsent' -Value 0 `
    -Because 'no Cortana in search'

###############################################################################
# Privacy - stop the suggestion and ad machinery                              #
###############################################################################
Say "Privacy"

Set-RegValue -Path $AdvertId -Name 'Enabled' -Value 0 `
    -Because 'disable the advertising ID used for cross-app tracking'

foreach ($v in @('SubscribedContent-338388Enabled',   # Start suggestions
                 'SubscribedContent-338389Enabled',   # tips and tricks
                 'SubscribedContent-353694Enabled',   # timeline suggestions
                 'SubscribedContent-353696Enabled',   # settings suggestions
                 'SystemPaneSuggestionsEnabled')) {
    Set-RegValue -Path $ContentD -Name $v -Value 0 -Because 'no "suggested content"'
}

Set-RegValue -Path $ContentD -Name 'SilentInstalledAppsEnabled' -Value 0 `
    -Because 'stop silently installing promoted apps'

Set-RegValue -Path $ContentD -Name 'PreInstalledAppsEnabled' -Value 0 `
    -Because 'no preinstalled bloat on new profiles'

Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy' `
    -Name 'TailoredExperiencesWithDiagnosticDataEnabled' -Value 0 `
    -Because 'no tailored experiences from diagnostic data'

# Telemetry: 0 (Security) is Enterprise-only; 1 (Basic) is the floor elsewhere
# and is what actually takes effect on Pro/Home.
Set-RegValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' `
    -Name 'AllowTelemetry' -Value 1 `
    -Because 'minimise diagnostic data (Basic)'

###############################################################################
# Performance                                                                 #
###############################################################################
Say "Performance"

Set-RegValue -Path 'HKCU:\Control Panel\Desktop' -Name 'MenuShowDelay' -Value '0' `
    -Type String -Because 'remove the menu open delay'

Set-RegValue -Path 'HKCU:\Control Panel\Desktop' -Name 'AutoEndTasks' -Value '1' `
    -Type String -Because 'do not block shutdown on hung apps'

Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize' `
    -Name 'StartupDelayInMSec' -Value 0 `
    -Because 'no artificial delay before startup apps run'

Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' `
    -Name 'RotatingLockScreenOverlayEnabled' -Value 0 `
    -Because 'no Spotlight overlay on the lock screen'

###############################################################################
# Developer                                                                   #
###############################################################################
Say "Developer"

# The capability win.ps1 existed for. Without it anything with deep trees
# (node_modules, nested Go/Rust builds) hits MAX_PATH at 260 characters.
Set-RegValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' `
    -Name 'LongPathsEnabled' -Value 1 `
    -Because 'allow paths longer than 260 characters'

Set-RegValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' `
    -Name 'AllowDevelopmentWithoutDevLicense' -Value 1 `
    -Because 'Developer Mode - lets chezmoi create symlinks without elevation'

###############################################################################
# Security - hardening only. Nothing here weakens a protection.               #
###############################################################################
Say "Security"

Set-RegValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel' `
    -Name 'DisableExceptionChainValidation' -Value 0 `
    -Because 'keep SEHOP exploit mitigation on'

Set-RegValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender' `
    -Name 'PUAProtection' -Value 1 `
    -Because 'block potentially unwanted applications (bundleware, adware)'

Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost' `
    -Name 'EnableWebContentEvaluation' -Value 1 `
    -Because 'keep SmartScreen checking downloaded content'

# SMBv1 is a deprecated, wormable protocol (EternalBlue). Nothing in a modern
# dev setup needs it.
if ($IsElevated) {
    if ($DryRun) {
        Note "would disable the SMBv1 client/server if present"
        $script:Applied++
    } else {
        try {
            $smb1 = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol `
                    -ErrorAction SilentlyContinue
            if ($smb1 -and $smb1.State -eq 'Enabled') {
                Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol `
                    -NoRestart -ErrorAction Stop | Out-Null
                Note "SMBv1 disabled (deprecated, wormable - EternalBlue)"
                $script:Applied++
            }
        } catch {
            Warn "could not query/disable SMBv1: $($_.Exception.Message)"
            $script:Skipped++
        }
    }
} else {
    Note "skip (needs admin): SMBv1 check"
    $script:Skipped++
}

###############################################################################
# Apply                                                                       #
###############################################################################

Write-Host ""
if ($DryRun) {
    Say "Dry run complete - $($script:Applied) change(s) would apply, $($script:Skipped) skipped."
    return
}

if (-not $SkipRestart -and $script:Applied -gt 0) {
    Say "Restarting Explorer so the changes take effect..."
    try {
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) {
            Start-Process explorer
        }
    } catch {
        Warn "could not restart Explorer - sign out and back in instead."
    }
}

Say "Done - $($script:Applied) change(s) applied, $($script:Skipped) skipped."
if (-not $IsElevated) {
    Warn "Re-run elevated to apply the machine-wide settings that were skipped."
}
Write-Host ""
