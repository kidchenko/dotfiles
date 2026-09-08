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
    [switch]$SkipRestart,

    # English interface. The home location (Thailand, etc.) is deliberately
    # NOT changed - that is what keeps weather, news and currency local.
    [string]$UiLanguage = 'en-US',

    # Power. AC values are generous because the machine is docked and plugged
    # in; DC values stay conservative because a laptop on battery that never
    # sleeps is a flat laptop.
    [int]$SleepMinutesAC   = 60,
    [int]$SleepMinutesDC   = 30,
    [int]$DisplayMinutesAC = 15,
    [int]$DisplayMinutesDC = 5,

    # 0 = do nothing, 1 = sleep, 2 = hibernate, 3 = shut down
    #
    # Both default to "do nothing" so closing the lid keeps music, downloads
    # and builds running. On battery this is safe because the idle sleep
    # timeout above still applies: audio playback holds a power request that
    # blocks idle sleep, so nothing is interrupted mid-track, and once
    # playback stops the machine sleeps $SleepMinutesDC minutes later. A
    # laptop closed and forgotten still goes to sleep on its own.
    [int]$LidClosedAC = 0,
    [int]$LidClosedDC = 0
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

$CONFIG_HOME_DIR = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HOME '.config' }

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

# Widgets. On Windows 11 25H2 the old HKCU 'TaskbarDa' value is ACL-protected -
# the key is writable but that value name specifically is denied, even
# elevated. The Group Policy value below is the supported route on Pro and
# removes both the taskbar button and the Win+W board (which is where the MSN
# feed lives, in whatever language MSN feels like using).
Set-RegValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' `
    -Name 'AllowNewsAndInterests' -Value 0 `
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
# Language & Region                                                           #
#                                                                             #
# English interface, local content. A fresh Windows install bought or set up  #
# in Thailand defaults the display language to Thai, which is what this        #
# section corrects - while deliberately leaving the home location alone so     #
# weather, news and currency stay local.                                       #
#                                                                             #
# Note: the Widgets board (Win+W) does NOT follow these settings. It renders   #
# the MSN feed via Edge WebView2, which carries its own content-language       #
# preference set from the Widgets gear icon. There is no supported registry    #
# key for it, so it cannot be scripted here.                                   #
###############################################################################
Say "Language and region"

if (Get-Command Get-WinUserLanguageList -ErrorAction SilentlyContinue) {
    $uiLangs = (Get-WinUserLanguageList | ForEach-Object { $_.LanguageTag })
    if ($uiLangs -contains $UiLanguage) {
        Note "UI language already includes $UiLanguage"
    } else {
        if ($DryRun) {
            Note "would set the display language to $UiLanguage (currently: $($uiLangs -join ', '))"
            $script:Applied++
        } else {
            try {
                $list = New-WinUserLanguageList $UiLanguage
                # Keep the existing languages after the preferred one so
                # installed keyboards are not silently removed.
                foreach ($tag in $uiLangs) {
                    if ($tag -ne $UiLanguage) { $list.Add($tag) }
                }
                Set-WinUserLanguageList $list -Force
                Set-WinUILanguageOverride -Language $UiLanguage
                Note "display language set to $UiLanguage (sign out to apply)"
                $script:Applied++
            } catch {
                Warn "could not set the display language: $($_.Exception.Message)"
                $script:Skipped++
            }
        }
    }

    $geo = (Get-WinHomeLocation).HomeLocation
    Note "home location left as '$geo' - local weather, news and currency"
}

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

# Win+V clipboard history: scrollback of everything copied, plus pinning.
# Off by default, and one of the highest-value switches on Windows.
Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Clipboard' -Name 'EnableClipboardHistory' -Value 1 `
    -Because 'Win+V clipboard history'

###############################################################################
# Lock screen - keep the photos, drop the advertising                         #
#                                                                             #
# Windows Spotlight mixes two things: the rotating background photos (nice)   #
# and "fun facts, tips, tricks and more" plus promoted app/game links (ads).  #
# These keep the photos and remove everything else.                           #
###############################################################################
Say "Lock screen"

Set-RegValue -Path $ContentD -Name 'RotatingLockScreenOverlayEnabled' -Value 0 `
    -Because 'no tips/facts overlay on the lock screen'

Set-RegValue -Path $ContentD -Name 'SubscribedContent-338387Enabled' -Value 0 `
    -Because 'no promoted content on the lock screen'

# The card row across the bottom of the lock screen (weather, sports, stocks,
# MSN quizzes) is Widgets, not Spotlight - the values above do not touch it.
# This is the documented policy for it on Windows 11 24H2 and later.
Set-RegValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' `
    -Name 'DisableWidgetsOnLockScreen' -Value 1 `
    -Because 'no widget cards on the lock screen'

# The same thing without admin: stops Windows picking widgets for you.
Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lock Screen' `
    -Name 'AutoSelectWidgetsOnLockScreen' -Value 0 `
    -Because 'do not auto-populate lock screen widgets'

Set-RegValue -Path $ContentD -Name 'SoftLandingEnabled' -Value 0 `
    -Because 'no Windows tips popups'

Set-RegValue -Path $ContentD -Name 'SubscribedContent-310093Enabled' -Value 0 `
    -Because 'no Windows welcome experience after updates'

Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement' `
    -Name 'ScoobeSystemSettingEnabled' -Value 0 `
    -Because 'no "finish setting up your device" nag'

# RotatingLockScreenEnabled is left ON deliberately: that is the photo
# rotation itself, which is the part worth keeping.

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
# Power                                                                       #
#                                                                             #
# Windows ships very aggressive defaults (5 min to sleep on AC), which is     #
# wrong for a docked development machine that runs builds, syncs and remote   #
# sessions.                                                                   #
#                                                                             #
# AC and DC are set separately on purpose:                                    #
#   * Lid closed does nothing on AC (docked, external monitor) but still      #
#     sleeps on battery - a laptop that stays awake in a bag overheats and    #
#     arrives flat.                                                           #
#   * Display-off is much shorter than sleep. Blanking the screen is cheap    #
#     and instantly reversible; sleeping is the disruptive step.              #
###############################################################################
Say "Power"

# The lid-close action is hidden from the Settings UI by default.
$SUB_BUTTONS = '4f971e89-eebd-4455-a8de-9e59040e7347'
$LID_ACTION  = '5ca83367-6e45-459f-a27b-476b1d01c936'

function Set-Power {
    param([string]$Description, [scriptblock]$Action)
    if (-not $IsElevated) {
        Note "skip (needs admin): $Description"
        $script:Skipped++
        return
    }
    if ($DryRun) {
        Note "would set $Description"
        $script:Applied++
        return
    }
    try {
        & $Action
        if ($LASTEXITCODE -eq 0 -or $null -eq $LASTEXITCODE) {
            Note $Description
            $script:Applied++
        } else {
            Warn "powercfg failed for '$Description' (exit $LASTEXITCODE)"
            $script:Skipped++
        }
    } catch {
        Warn "could not set '$Description': $($_.Exception.Message)"
        $script:Skipped++
    }
}

$lidNames = @{ 0 = 'do nothing'; 1 = 'sleep'; 2 = 'hibernate'; 3 = 'shut down' }

Set-Power "sleep after $SleepMinutesAC min on AC" {
    powercfg /change standby-timeout-ac $SleepMinutesAC
}
Set-Power "sleep after $SleepMinutesDC min on battery" {
    powercfg /change standby-timeout-dc $SleepMinutesDC
}
Set-Power "display off after $DisplayMinutesAC min on AC" {
    powercfg /change monitor-timeout-ac $DisplayMinutesAC
}
Set-Power "display off after $DisplayMinutesDC min on battery" {
    powercfg /change monitor-timeout-dc $DisplayMinutesDC
}
# Windows hides the lid-close action from the Settings UI by default - it is
# absent from `powercfg /q SCHEME_CURRENT SUB_BUTTONS` until unhidden. Setting
# it by GUID works either way, but unhiding means the value is also visible
# and editable under Power Options rather than being invisibly overridden.
Set-Power "unhide the lid-close action in Power Options" {
    powercfg /attributes $SUB_BUTTONS $LID_ACTION -ATTRIB_HIDE
}

Set-Power "lid closed on AC: $($lidNames[$LidClosedAC])" {
    powercfg /setacvalueindex SCHEME_CURRENT $SUB_BUTTONS $LID_ACTION $LidClosedAC
}
Set-Power "lid closed on battery: $($lidNames[$LidClosedDC])" {
    powercfg /setdcvalueindex SCHEME_CURRENT $SUB_BUTTONS $LID_ACTION $LidClosedDC
}
# setacvalueindex/setdcvalueindex only write the scheme - it has to be
# re-activated for the change to take effect.
Set-Power "activate the updated power scheme" {
    powercfg /setactive SCHEME_CURRENT
}

###############################################################################
# Hot corners                                                                 #
#                                                                             #
# Windows has no native hot-corner feature - there is no registry key and no  #
# Settings page for it. The behaviour comes from an AutoHotkey script that    #
# chezmoi installs to ~/.config/dotfiles/hot-corners.ahk; this only wires it  #
# up to run at logon via a Startup shortcut.                                  #
###############################################################################
Say "Hot corners"

$ahkScript = Join-Path $CONFIG_HOME_DIR 'dotfiles\hot-corners.ahk'
$startupDir = [System.Environment]::GetFolderPath('Startup')
$shortcut  = Join-Path $startupDir 'dotfiles-hot-corners.lnk'

if (-not (Test-Path $ahkScript)) {
    Note "skip: hot-corners.ahk not found (run 'chezmoi apply' first)"
    $script:Skipped++
} elseif (Test-Path $shortcut) {
    Note "hot corners already run at logon"
} else {
    $ahkExe = $null
    foreach ($c in @(
        (Join-Path $env:ProgramFiles 'AutoHotkey\v2\AutoHotkey.exe'),
        (Join-Path $env:ProgramFiles 'AutoHotkey\AutoHotkey.exe')
    )) { if (Test-Path $c) { $ahkExe = $c; break } }

    if (-not $ahkExe) {
        Note "skip: AutoHotkey not installed (choco install autohotkey)"
        $script:Skipped++
    } elseif ($DryRun) {
        Note "would create a Startup shortcut running hot-corners.ahk at logon"
        $script:Applied++
    } else {
        try {
            $wsh = New-Object -ComObject WScript.Shell
            $lnk = $wsh.CreateShortcut($shortcut)
            $lnk.TargetPath = $ahkExe
            $lnk.Arguments  = "`"$ahkScript`""
            $lnk.Description = 'macOS-style hot corners (dotfiles)'
            $lnk.Save()
            Note "hot corners will start at logon (Win+Alt+H pauses them)"
            $script:Applied++
        } catch {
            Warn "could not create the Startup shortcut: $($_.Exception.Message)"
            $script:Skipped++
        }
    }
}

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
