#Requires -Version 5.1
<#
.SYNOPSIS
    Install dotfiles scheduled tasks on Windows.

.DESCRIPTION
    Windows counterpart of tools/setup-cron.sh. Reads the SAME job definitions
    from ~/.config/dotfiles/config.yaml (cron.jobs) and registers them with the
    Windows Task Scheduler instead of crontab.

    Pure PowerShell end to end - nothing here invokes bash. config.yaml names
    each job by its .sh filename because that config is shared with macOS, but
    Windows runs the .ps1 sibling in cron/. A job with no .ps1 counterpart is
    reported and skipped rather than scheduled.

    Schedules are written as cron expressions to keep one config for both
    platforms. Only the subset the jobs actually use is supported:

        m h * * *      -> daily at h:m
        m h * * D      -> weekly on day D (0=Sunday .. 6=Saturday)

    Anything else (ranges, steps, lists, day-of-month) is reported and skipped
    rather than silently scheduled at the wrong time.

.PARAMETER DryRun
    Show what would be registered without changing anything.

.PARAMETER List
    List the currently registered dotfiles tasks.

.PARAMETER Remove
    Remove all dotfiles tasks and exit.
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$List,
    [switch]$Remove
)

$ErrorActionPreference = 'Stop'

# Tasks live in their own folder so cleanup can never touch anything else.
$TASK_PATH = '\dotfiles\'
$TASK_PREFIX = 'dotfiles-'

$CONFIG_FILE = if ($env:XDG_CONFIG_HOME) {
    Join-Path $env:XDG_CONFIG_HOME 'dotfiles\config.yaml'
} else {
    Join-Path $HOME '.config\dotfiles\config.yaml'
}

$CRON_DIR = if ($env:XDG_DATA_HOME) {
    Join-Path $env:XDG_DATA_HOME 'chezmoi\cron'
} else {
    Join-Path $HOME '.local\share\chezmoi\cron'
}

function Say([string]$m)  { Write-Host "[cron] $m" -ForegroundColor Green }
function Warn([string]$m) { Write-Host "[cron] $m" -ForegroundColor Yellow }
function Fail([string]$m) { Write-Host "[cron] ERROR: $m" -ForegroundColor Red; exit 1 }

# Resolve a job name from config.yaml to its Windows implementation.
#
# config.yaml names the jobs with their .sh filenames because that config is
# shared with macOS/Linux. Windows runs the .ps1 sibling instead - the same
# "extension encodes the OS" rule the hooks runner uses. Nothing here shells
# out to bash: the .sh jobs are hardcoded to Homebrew paths and would fail on
# Windows anyway, so a wrapper would only have scheduled a guaranteed error.
function Resolve-JobScript {
    param([string]$ScriptName)
    $base = $ScriptName -replace '\.(sh|ps1)$', ''
    $candidate = Join-Path $CRON_DIR "$base.ps1"
    if (Test-Path $candidate) { return $candidate }
    return $null
}

# Convert a cron expression to a ScheduledTaskTrigger.
# Returns $null (with a warning) for anything outside the supported subset -
# a wrong schedule is worse than a missing one.
function ConvertFrom-CronSchedule {
    param([string]$Schedule, [string]$JobName)

    $parts = $Schedule -split '\s+' | Where-Object { $_ -ne '' }
    if ($parts.Count -ne 5) {
        Warn "  Skipping '$JobName': expected 5 cron fields, got $($parts.Count) ('$Schedule')"
        return $null
    }

    $minute = $parts[0]; $hour = $parts[1]
    $dom    = $parts[2]; $month = $parts[3]; $dow = $parts[4]

    foreach ($f in @($minute, $hour)) {
        if ($f -notmatch '^\d+$') {
            Warn "  Skipping '$JobName': only fixed minute/hour supported (got '$Schedule')"
            return $null
        }
    }
    if ($dom -ne '*' -or $month -ne '*') {
        Warn "  Skipping '$JobName': day-of-month and month must be '*' (got '$Schedule')"
        return $null
    }

    $at = (Get-Date -Hour ([int]$hour) -Minute ([int]$minute) -Second 0)

    if ($dow -eq '*') {
        return New-ScheduledTaskTrigger -Daily -At $at
    }

    if ($dow -notmatch '^[0-6]$') {
        Warn "  Skipping '$JobName': only '*' or a single day 0-6 supported (got '$dow')"
        return $null
    }

    # cron: 0=Sunday .. 6=Saturday, which matches [System.DayOfWeek]
    $day = [System.DayOfWeek][int]$dow
    return New-ScheduledTaskTrigger -Weekly -DaysOfWeek $day -At $at
}

# Render a trigger back into something a human can check against the cron
# expression. DaysOfWeek on the CIM object is a bitmask, not an enum.
function Format-Trigger {
    param($Trigger)
    $mask = @{ 1='Sun'; 2='Mon'; 4='Tue'; 8='Wed'; 16='Thu'; 32='Fri'; 64='Sat' }
    $time = ([datetime]$Trigger.StartBoundary).ToString('HH:mm')
    if ($Trigger.DaysOfWeek) {
        $names = @()
        foreach ($bit in $mask.Keys | Sort-Object) {
            if ([int]$Trigger.DaysOfWeek -band $bit) { $names += $mask[$bit] }
        }
        return "weekly $($names -join ',') at $time"
    }
    return "daily at $time"
}

function Get-DotfilesTasks {
    Get-ScheduledTask -TaskPath $TASK_PATH -ErrorAction SilentlyContinue
}

function Remove-DotfilesTasks {
    $existing = Get-DotfilesTasks
    if (-not $existing) { return 0 }
    foreach ($t in $existing) {
        Unregister-ScheduledTask -TaskName $t.TaskName -TaskPath $TASK_PATH -Confirm:$false
    }
    return @($existing).Count
}

# --- List / Remove short-circuits ----------------------------------------

if ($List) {
    $tasks = Get-DotfilesTasks
    if (-not $tasks) { Say "No dotfiles tasks registered."; exit 0 }
    Write-Host ""
    $tasks | ForEach-Object {
        $info = Get-ScheduledTaskInfo -TaskName $_.TaskName -TaskPath $TASK_PATH -ErrorAction SilentlyContinue
        [PSCustomObject]@{
            Task     = $_.TaskName -replace "^$TASK_PREFIX", ''
            State    = $_.State
            NextRun  = $info.NextRunTime
            LastRun  = $info.LastRunTime
        }
    } | Format-Table -AutoSize
    exit 0
}

if ($Remove) {
    $n = Remove-DotfilesTasks
    Say "Removed $n dotfiles task(s)."
    exit 0
}

# --- Dependencies ---------------------------------------------------------

if (-not (Get-Command Register-ScheduledTask -ErrorAction SilentlyContinue)) {
    Fail "The ScheduledTasks module is unavailable on this system."
}

# Prefer pwsh 7 when present, else the built-in Windows PowerShell. Resolved to
# a full path so the task does not depend on the service account's PATH.
$PowerShellExe = (Get-Command pwsh -CommandType Application -ErrorAction SilentlyContinue |
                  Select-Object -First 1).Source
if (-not $PowerShellExe) {
    $PowerShellExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
}
if (-not (Test-Path $PowerShellExe)) {
    Fail "No PowerShell executable found to run the scheduled jobs."
}

if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
    Fail "yq not installed. Install with: choco install yq"
}

if (-not (Test-Path $CONFIG_FILE)) {
    Warn "Config file not found: $CONFIG_FILE"
    Warn "Run 'chezmoi apply' to create it"
    exit 1
}

Say "Setting up scheduled tasks from config.yaml..."
Say "Scripts directory: $CRON_DIR"
Write-Host ""

$jobCount = [int](yq -r '.cron.jobs | length' $CONFIG_FILE 2>$null)
if (-not $jobCount -or $jobCount -eq 0) {
    Warn "No cron jobs defined in config.yaml"
    exit 0
}

# --- Clean up previous registrations -------------------------------------
# Scoped to the \dotfiles\ task folder, mirroring the bash version's filtered
# crontab rewrite. Re-running is therefore idempotent.
if (-not $DryRun) {
    Say "Cleaning up old entries..."
    $removed = Remove-DotfilesTasks
    if ($removed -gt 0) { Say "  removed $removed stale task(s)" }
}

# --- Register each job ----------------------------------------------------

$installed = 0
$skipped = 0

for ($i = 0; $i -lt $jobCount; $i++) {
    $script      = yq -r ".cron.jobs[$i].script" $CONFIG_FILE 2>$null
    $schedule    = yq -r ".cron.jobs[$i].schedule" $CONFIG_FILE 2>$null
    $description = yq -r ".cron.jobs[$i].description" $CONFIG_FILE 2>$null

    $scriptPath = Resolve-JobScript -ScriptName $script
    if (-not $scriptPath) {
        $base = $script -replace '\.(sh|ps1)$', ''
        Warn "  Skipping '$script': no Windows implementation at $CRON_DIR\$base.ps1"
        $skipped++
        continue
    }

    $trigger = ConvertFrom-CronSchedule -Schedule $schedule -JobName $script
    if (-not $trigger) { $skipped++; continue }

    $taskName = $TASK_PREFIX + ($script -replace '\.sh$', '')

    # -File, not -Command: no nested quoting to get wrong, and the path is
    # passed as a single argument even when it contains spaces.
    $action = New-ScheduledTaskAction -Execute $PowerShellExe `
        -Argument "-NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""

    if ($DryRun) {
        # Show the RESOLVED schedule, not the cron string we were given - the
        # whole point of the dry run is to catch a bad translation.
        Write-Host "  Would add: $description"
        Write-Host "    $taskName  <-  $schedule  ->  $(Format-Trigger $trigger)"
        $installed++
        continue
    }

    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
        -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 2)

    try {
        Register-ScheduledTask -TaskName $taskName -TaskPath $TASK_PATH `
            -Action $action -Trigger $trigger -Settings $settings `
            -Description $description -Force | Out-Null
        Say "+ $description"
        $installed++
    } catch {
        Warn "  Failed to register '$taskName': $($_.Exception.Message)"
        $skipped++
    }
}

Write-Host ""
if ($DryRun) {
    Say "Dry run complete. No changes made. ($installed would install, $skipped skipped)"
} else {
    Say "Scheduled tasks installed ($installed installed, $skipped skipped)"
    Write-Host ""
    Say "Current dotfiles tasks:"
    & $PSCommandPath -List
}
