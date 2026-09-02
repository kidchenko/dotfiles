#Requires -Version 5.1
<#
.SYNOPSIS
    Back up, list and restore project folders (Windows).

.DESCRIPTION
    PowerShell counterpart of tools/backup-projects.sh. Reads the SAME backup:
    section of ~/.config/dotfiles/config.yaml, produces the same
    project-backup-<timestamp>.zip naming, and honours the same retention -
    the declarations are shared, only the executor is per-platform.

    Archives are plain zips with HOME-relative entry paths, so an archive made
    here restores on macOS and vice versa.

.PARAMETER Command
    backup (default), list, or restore.

.PARAMETER DryRun
    Preview without writing anything.

.PARAMETER Upload
    Upload the finished archive with rclone (needs backup.remote.enabled).
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('backup', 'list', 'restore')]
    [string]$Command = 'backup',

    [switch]$DryRun,
    [switch]$Upload
)

$ErrorActionPreference = 'Continue'

Add-Type -AssemblyName System.IO.Compression.FileSystem

# --- Paths ----------------------------------------------------------------

$LogDir = if ($env:XDG_STATE_HOME) {
    Join-Path $env:XDG_STATE_HOME 'dotfiles'
} else {
    Join-Path $HOME '.local\state\dotfiles'
}
$LogFile = Join-Path $LogDir 'backup-cron.log'

$DataHome = if ($env:XDG_DATA_HOME) { $env:XDG_DATA_HOME } else { Join-Path $HOME '.local\share' }
$BackupDir = Join-Path $DataHome 'dotfiles\backups'

$ConfigFile = if ($env:XDG_CONFIG_HOME) {
    Join-Path $env:XDG_CONFIG_HOME 'dotfiles\config.yaml'
} else {
    Join-Path $HOME '.config\dotfiles\config.yaml'
}

if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

function Log([string]$Message) {
    $line = "[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    $line | Add-Content -Path $LogFile
    Write-Verbose $line
}

# --- Defaults, overridden by config.yaml ----------------------------------

$Folders = @('kidchenko', 'lambda3', 'jetabroad', 'thoughtworks', 'sevenpeaks', 'isho')
$Excludes = @('node_modules', '.git', 'vendor', '.venv', '__pycache__', 'dist', 'build', 'bin', 'obj')
$RetentionDays = 7
$RemoteEnabled = $false
$RcloneRemote = 'GoogleDrive'
$RclonePath = 'DotfilesBackups/'

if (Test-Path $ConfigFile) {
    $yq = Get-Command yq -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($yq) {
        $f = & $yq.Source -r '.backup.folders[]?' $ConfigFile 2>$null |
             Where-Object { $_ -and $_ -ne 'null' }
        if ($f) { $Folders = @($f) }

        $e = & $yq.Source -r '.backup.exclude[]?' $ConfigFile 2>$null |
             Where-Object { $_ -and $_ -ne 'null' }
        if ($e) { $Excludes = @($e) }

        $r = & $yq.Source -r '.backup.local.retention_days' $ConfigFile 2>$null
        if ($r -match '^\d+$') { $RetentionDays = [int]$r }

        # Raw read, not `// ""`: yq treats `false` as empty in the alternative
        # operator, which silently defeats a `false` kill switch.
        $re = & $yq.Source -r '.backup.remote.enabled' $ConfigFile 2>$null
        $RemoteEnabled = ($re -eq 'true')

        $rr = & $yq.Source -r '.backup.remote.rclone_remote' $ConfigFile 2>$null
        if ($rr -and $rr -ne 'null') { $RcloneRemote = $rr }

        $rp = & $yq.Source -r '.backup.remote.rclone_path' $ConfigFile 2>$null
        if ($rp -and $rp -ne 'null') { $RclonePath = $rp }
    } else {
        Log "WARN: yq not installed - using built-in defaults"
    }
} else {
    Log "Config file not found: $ConfigFile - using built-in defaults"
}

# --- list / restore -------------------------------------------------------

function Get-Archives {
    if (-not (Test-Path $BackupDir)) { return @() }
    return @(Get-ChildItem $BackupDir -Filter 'project-backup-*.zip' -File -ErrorAction SilentlyContinue |
             Sort-Object LastWriteTime -Descending)
}

if ($Command -eq 'list') {
    $archives = Get-Archives
    if ($archives.Count -eq 0) { Write-Host "No backups found in $BackupDir"; exit 0 }

    Write-Host ""
    Write-Host "Backups in $BackupDir"
    $archives | Select-Object @{n='Backup';e={$_.Name}},
                              @{n='Size';e={"{0:N1} MB" -f ($_.Length / 1MB)}},
                              LastWriteTime |
        Format-Table -AutoSize
    exit 0
}

if ($Command -eq 'restore') {
    $archives = Get-Archives
    if ($archives.Count -eq 0) { Write-Host "No backups found in $BackupDir"; exit 1 }

    Write-Host ""
    Write-Host "Available backups:"
    for ($i = 0; $i -lt $archives.Count; $i++) {
        "  [{0}] {1}  ({2:N1} MB, {3})" -f ($i + 1), $archives[$i].Name,
            ($archives[$i].Length / 1MB), $archives[$i].LastWriteTime
    }
    Write-Host ""

    $choice = Read-Host "Select a backup to restore [1-$($archives.Count)] (Enter to cancel)"
    if (-not $choice) { Write-Host "Cancelled."; exit 0 }
    if ($choice -notmatch '^\d+$' -or [int]$choice -lt 1 -or [int]$choice -gt $archives.Count) {
        Write-Host "Invalid selection." -ForegroundColor Red; exit 1
    }

    $selected = $archives[[int]$choice - 1]

    Write-Host ""
    Write-Host "Contents of $($selected.Name):"
    $zip = [System.IO.Compression.ZipFile]::OpenRead($selected.FullName)
    try {
        $zip.Entries | Select-Object -First 25 | ForEach-Object { "    $($_.FullName)" }
        if ($zip.Entries.Count -gt 25) { "    ... and $($zip.Entries.Count - 25) more" }
    } finally { $zip.Dispose() }

    Write-Host ""
    # Extraction overwrites files in place under $HOME - never do that silently.
    Write-Host "This extracts into $HOME and OVERWRITES existing files." -ForegroundColor Yellow
    $confirm = Read-Host "Type 'yes' to continue"
    if ($confirm -ne 'yes') { Write-Host "Cancelled."; exit 0 }

    if ($DryRun) { Write-Host "DRY RUN: would extract $($selected.Name) into $HOME"; exit 0 }

    $restored = 0
    $zip = [System.IO.Compression.ZipFile]::OpenRead($selected.FullName)
    try {
        foreach ($entry in $zip.Entries) {
            if (-not $entry.Name) { continue }   # directory entry

            $target = Join-Path $HOME $entry.FullName
            # Guard against path traversal in a crafted archive
            $full = [System.IO.Path]::GetFullPath($target)
            if (-not $full.StartsWith([System.IO.Path]::GetFullPath($HOME))) {
                Write-Host "  skipped (unsafe path): $($entry.FullName)" -ForegroundColor Yellow
                continue
            }

            $dir = Split-Path $full -Parent
            if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $full, $true)
            $restored++
        }
    } finally { $zip.Dispose() }

    Log "Restored $restored file(s) from $($selected.Name)"
    Write-Host "Restored $restored file(s) from $($selected.Name)" -ForegroundColor Green
    exit 0
}

# --- Collect files --------------------------------------------------------

Log "=== Starting weekly backup ==="

$existing = @()
foreach ($folder in $Folders) {
    $path = if ([System.IO.Path]::IsPathRooted($folder)) { $folder } else { Join-Path $HOME $folder }
    if (Test-Path $path) {
        $existing += $path
        Log "  + $path"
    } else {
        Log "  ! $path (not found, skipping)"
    }
}

if ($existing.Count -eq 0) {
    Log "ERROR: none of the configured folders exist - nothing to back up"
    exit 1
}

# Excludes are directory/file NAME patterns (node_modules, *.pyc), matched
# against every path segment - same semantics as the zip --exclude globs.
$dirExcludes  = @($Excludes | Where-Object { $_ -notmatch '[*?]' })
$globExcludes = @($Excludes | Where-Object { $_ -match '[*?]' })

function Test-Excluded {
    param([string]$FullPath, [string]$Root)
    $relative = $FullPath.Substring($Root.Length).TrimStart('\', '/')
    foreach ($segment in ($relative -split '[\\/]')) {
        if ($dirExcludes -contains $segment) { return $true }
        foreach ($g in $globExcludes) {
            if ($segment -like $g) { return $true }
        }
    }
    return $false
}

Log "Collecting files (excluding $($Excludes.Count) patterns)..."

$files = New-Object System.Collections.Generic.List[object]
foreach ($root in $existing) {
    $parent = Split-Path $root -Parent
    Get-ChildItem -LiteralPath $root -Recurse -File -Force -ErrorAction SilentlyContinue |
        ForEach-Object {
            if (-not (Test-Excluded -FullPath $_.FullName -Root $parent)) {
                # Built as a variable rather than inline in .Add(): inside a
                # method call's parentheses the parser reads the comma in
                # TrimStart('\', '/') as an argument separator and the whole
                # statement fails to parse.
                $entry = $_.FullName.Substring($parent.Length).TrimStart('\', '/')
                $entry = $entry -replace '\\', '/'
                $item = [PSCustomObject]@{
                    Full  = $_.FullName
                    Entry = $entry
                }
                $files.Add($item)
            }
        }
}

Log "  $($files.Count) file(s) to archive"

if ($files.Count -eq 0) {
    Log "ERROR: nothing to archive after exclusions"
    exit 1
}

# --- Create the archive ---------------------------------------------------

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$archiveName = "project-backup-$timestamp.zip"
$archivePath = Join-Path $BackupDir $archiveName

if ($DryRun) {
    Log "DRY RUN: would create $archivePath with $($files.Count) file(s)"
} else {
    if (-not (Test-Path $BackupDir)) {
        New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    }

    Log "Creating archive: $archiveName"
    $added = 0
    $failed = 0
    try {
        $zip = [System.IO.Compression.ZipFile]::Open($archivePath, 'Create')
        try {
            foreach ($f in $files) {
                try {
                    [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                        $zip, $f.Full, $f.Entry,
                        [System.IO.Compression.CompressionLevel]::Optimal)
                    $added++
                } catch {
                    # Locked or vanished mid-run: skip the file, keep the backup
                    $failed++
                }
            }
        } finally {
            $zip.Dispose()
        }
    } catch {
        Log "ERROR: Backup failed: $($_.Exception.Message)"
        if (Test-Path $archivePath) { Remove-Item $archivePath -Force -ErrorAction SilentlyContinue }
        exit 1
    }

    $sizeMB = [math]::Round((Get-Item $archivePath).Length / 1MB, 1)
    Log "Backup completed successfully: $archiveName (${sizeMB} MB, $added file(s), $failed skipped)"
}

# --- Optional remote upload ----------------------------------------------

if ($Upload -and $RemoteEnabled) {
    $rclone = Get-Command rclone -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $rclone) {
        Log "WARN: rclone not installed. Install with: choco install rclone"
    } elseif ($DryRun) {
        Log "DRY RUN: would upload $archiveName to ${RcloneRemote}:${RclonePath}"
    } else {
        Log "Uploading to ${RcloneRemote}:${RclonePath}..."
        & $rclone.Source copy $archivePath "${RcloneRemote}:${RclonePath}" 2>&1 |
            Add-Content -Path $LogFile
        if ($LASTEXITCODE -eq 0) { Log "Upload complete" } else { Log "ERROR: Upload failed" }
    }
}

# --- Retention ------------------------------------------------------------
# cron/backup.sh keeps the 2 most recent archives regardless of age; the
# retention_days value governs the older sweep. Both are applied here.

if (-not $DryRun -and (Test-Path $BackupDir)) {
    $archives = Get-ChildItem $BackupDir -Filter 'project-backup-*.zip' -File -ErrorAction SilentlyContinue |
                Sort-Object LastWriteTime -Descending

    $keep = @($archives | Select-Object -First 2)
    $cutoff = (Get-Date).AddDays(-$RetentionDays)

    foreach ($a in $archives) {
        if ($keep -contains $a) { continue }
        if ($a.LastWriteTime -lt $cutoff) {
            Log "Removing old backup: $($a.Name)"
            Remove-Item $a.FullName -Force -ErrorAction SilentlyContinue
        }
    }
}

Log "=== Finished ==="
