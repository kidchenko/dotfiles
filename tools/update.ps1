#Requires -Version 5.1
<#
.SYNOPSIS
    Check for dotfiles updates and offer to apply them (Windows).

.DESCRIPTION
    Windows counterpart of tools/update.sh, driven by the PowerShell profile
    (home/dot_config/powershell/login.ps1.tmpl) the way .zlogin drives update.sh
    on macOS. Same contract as the Zsh side: when the tracked branch is ahead,
    ask before touching anything, and never apply unasked. There is no throttle
    - every shell that finds the branch behind asks, including one that already
    asked and was told no.

    What differs is the scheduling, because the cost profile differs. .zlogin
    runs once per login shell; a PowerShell profile runs on every pwsh start,
    including every script and subshell, so nothing expensive may sit on the
    startup path. Work is ordered by what the user can feel:

      At profile load (-Watch), a few milliseconds:
        Compare HEAD against the tracked remote ref already on disk, by reading
        .git directly - no network, and no process spawn either. If it is
        behind, ask right there, next to the greeting, which is where the Zsh
        side asks too.

      At the first prompt render:
        Spawn the detached `git fetch`. The shell is already on screen by then,
        so its ~50ms costs the user nothing. Deliberately not done at profile
        load, where it would be the single most expensive line in this startup
        path.

      At a later prompt render, once that fetch has exited:
        Compare again, now against refs this shell fetched, and ask if the first
        comparison came up clean. This is what keeps a push from being reported
        a shell late, the way a fetch-and-immediately-compare would report it.

    So the common case answers instantly from local refs, the network never
    blocks anything, and a commit pushed a minute ago is still caught by the
    shell you are sitting in.

    A non-interactive shell renders no prompt, so it never reaches the fetch or
    the second comparison; and Read-Host is skipped under redirected input,
    where EOF would read as a silent "no". Between them that is the
    interactivity check - there is no separate one to get wrong.

    Unlike update.sh this stays silent when the branch is current. update.sh can
    afford "Already up to date." because it runs once per login; here that is a
    line of noise on top of every terminal.

    Set DOTFILES_SKIP_UPDATE_CHECK to any value to disable all of it.

.PARAMETER Watch
    Check now, then install the prompt wrapper described above. Must be invoked
    after anything else that defines `prompt` (oh-my-posh) - it calls through to
    whatever is in effect at the time.

.PARAMETER Start
    Start the detached fetch and return the process handle. Used by the prompt
    wrapper; also useful on its own for testing.

.EXAMPLE
    # In the profile, as the last line:
    & tools/update.ps1 -Watch

.EXAMPLE
    # Check right now against already-fetched refs.
    & tools/update.ps1
#>
[CmdletBinding()]
param(
    [switch]$Watch,
    [switch]$Start
)

$ErrorActionPreference = 'Continue'

$DotfilesDir = if ($env:XDG_DATA_HOME) {
    Join-Path $env:XDG_DATA_HOME 'chezmoi'
} else {
    Join-Path $HOME '.local/share/chezmoi'
}

function Say([string]$Message) { Write-Host "[dotfiles] $Message" }

function Test-Checkable {
    if ($env:DOTFILES_SKIP_UPDATE_CHECK) { return $false }
    return (Test-Path (Join-Path $DotfilesDir '.git'))
}

function Start-DotfilesFetch {
    if (-not (Test-Checkable)) { return $null }

    # The child has no console of its own, so a credential prompt would hang it
    # forever and leak a stuck git process into every shell. Refuse to ask.
    $previous = $env:GIT_TERMINAL_PROMPT
    $env:GIT_TERMINAL_PROMPT = '0'
    try {
        # No Get-Command git guard: it costs a PATH scan on every shell, and a
        # missing git fails this call anyway, which is already handled.
        Start-Process -FilePath 'git' `
            -ArgumentList @('-C', $DotfilesDir, 'fetch', '--quiet') `
            -NoNewWindow -PassThru -ErrorAction Stop
    } catch {
        $null
    } finally {
        $env:GIT_TERMINAL_PROMPT = $previous
    }
}

function Resolve-GitRef([string]$GitDir, [string]$Ref) {
    $loose = Join-Path $GitDir $Ref
    if (Test-Path $loose) { return (Get-Content $loose -Raw -ErrorAction SilentlyContinue).Trim() }

    $packed = Join-Path $GitDir 'packed-refs'
    if (Test-Path $packed) {
        $pattern = '^([0-9a-f]{40})\s+' + [regex]::Escape($Ref) + '$'
        foreach ($line in (Get-Content $packed -ErrorAction SilentlyContinue)) {
            if ($line -match $pattern) { return $Matches[1] }
        }
    }
    return $null
}

# HEAD and its upstream, read straight out of .git. `git rev-parse` measures
# ~70ms on this machine - a process spawn, on the startup path of every single
# shell, to print two hashes that are sitting in files. Returns $null for
# anything unusual (detached HEAD, .git as a file in a worktree, a branch with
# no upstream configured), and the caller falls back to git for those.
function Read-GitRevs([string]$GitDir) {
    try {
        $head = (Get-Content (Join-Path $GitDir 'HEAD') -Raw -ErrorAction Stop).Trim()
        if ($head -notmatch '^ref:\s*(refs/heads/(.+))$') { return $null }
        $branchRef = $Matches[1]
        $branch    = $Matches[2]

        # Upstream is a config lookup: [branch "main"] remote = / merge =
        $remote = $null; $merge = $null; $inSection = $false
        foreach ($line in (Get-Content (Join-Path $GitDir 'config') -ErrorAction Stop)) {
            $t = $line.Trim()
            if ($t.StartsWith('[')) {
                $inSection = (($t -replace '\s+', ' ') -eq ('[branch "' + $branch + '"]'))
            } elseif ($inSection) {
                if     ($t -match '^remote\s*=\s*(\S+)') { $remote = $Matches[1] }
                elseif ($t -match '^merge\s*=\s*refs/heads/(\S+)') { $merge = $Matches[1] }
            }
        }
        if (-not $remote -or -not $merge) { return $null }

        $localSha    = Resolve-GitRef $GitDir $branchRef
        $upstreamSha = Resolve-GitRef $GitDir "refs/remotes/$remote/$merge"
        if (-not $localSha -or -not $upstreamSha) { return $null }
        return @($localSha, $upstreamSha)
    } catch {
        return $null
    }
}

# Returns $true when it put a question or a message on screen.
function Invoke-DotfilesCheck {
    if (-not (Test-Checkable)) { return $false }

    $revs = Read-GitRevs (Join-Path $DotfilesDir '.git')
    if (-not $revs) {
        # Both revisions from one spawn: asking separately doubles the cost.
        $revs = @(& git -C $DotfilesDir rev-parse '@' '@{u}' 2>$null)
        if ($LASTEXITCODE -ne 0 -or $revs.Count -lt 2) { return $false }
    }

    # Equal is the overwhelmingly common case, and it got here without spawning
    # anything. Everything below is on the rare path where there is news.
    if ($revs[0] -eq $revs[1]) { return $false }

    # Behind, ahead, or diverged - only the first is ours to fix. `chezmoi
    # update` pulls, so offering it on top of unpushed local work is wrong.
    $counts = -split (& git -C $DotfilesDir rev-list --left-right --count '@...@{u}' 2>$null)
    $ahead  = if ($counts.Count -ge 2) { [int]$counts[0] } else { 0 }
    $behind = if ($counts.Count -ge 2) { [int]$counts[1] } else { 0 }

    if ($ahead -gt 0) {
        Say "Local dotfiles have diverged from the remote ($ahead ahead, $behind behind)."
        return $true
    }

    $noun = if ($behind -eq 1) { 'commit' } else { 'commits' }

    if (-not (Get-Command chezmoi -ErrorAction SilentlyContinue)) {
        Say "New version available ($behind $noun behind), but it cannot be applied - the dotfiles installation is incomplete."
        return $true
    }

    # Answering needs a keyboard. Under redirected input there is nobody there,
    # and Read-Host would take EOF as a silent "no". Nothing is printed either:
    # a script, subshell or CI run cannot act on the news, and a stray line on
    # their stdout is worse than silence. The next interactive shell asks.
    if ([Console]::IsInputRedirected) { return $false }

    # The announcement is the question. Printing the news on its own line first
    # and then asking reads as two events for one piece of information.
    $reply = Read-Host "[dotfiles] New version available ($behind $noun behind). Update now? [y/n]"
    if ($reply -match '^\s*[Yy]') {
        chezmoi update
        if ($LASTEXITCODE -eq 0) {
            Say 'Updated successfully!'
            Say 'Open a new shell to pick up profile changes.'
        } else {
            Say "Update failed. Run 'dotfiles update' to retry."
        }
    } else {
        Say 'Update skipped.'
    }
    return $true
}

function Install-DotfilesPromptWatcher([bool]$AlreadyAsked) {
    if ($global:DotfilesUpdateWatch) { return }   # profile sourced twice

    $global:DotfilesUpdateWatch = [pscustomobject]@{
        Fetch = $null
        Asked = $AlreadyAsked
        Done  = $false
    }
    $global:DotfilesUpdateScript = $PSCommandPath

    # oh-my-posh installs its own prompt during profile load, so this has to run
    # after it. Call through to whatever is in effect rather than replacing it.
    #
    # Read via the Function provider, not Get-Command: Get-Command searches
    # every command type, so asking it for `prompt` walks PATH looking for a
    # prompt executable and costs ~270ms - by far the most expensive thing this
    # script was doing.
    $inner = if (Test-Path 'function:prompt') { (Get-Item 'function:prompt').ScriptBlock } else { $null }

    # Never capture our own wrapper as the inner prompt: that makes prompt call
    # itself forever, which is the worst failure available in a shell. The guard
    # above normally prevents a second install; this covers the case where the
    # global state was cleared while the wrapper was still in place.
    if ($inner -and $inner.ToString() -like '*DotfilesUpdateWatch*') {
        $inner = $global:DotfilesInnerPrompt
    }

    if (-not $inner) {
        $inner = { "PS $($ExecutionContext.SessionState.Path.CurrentLocation)$('>' * ($NestedPromptLevel + 1)) " }
    }
    $global:DotfilesInnerPrompt = $inner

    function global:prompt {
        $state = $global:DotfilesUpdateWatch
        if ($state -and -not $state.Done) {
            # A failing update check must never take the prompt down with it.
            try {
                if (-not $state.Fetch) {
                    $state.Fetch = & $global:DotfilesUpdateScript -Start
                    if (-not $state.Fetch) { $state.Done = $true }
                } elseif ($state.Fetch.HasExited) {
                    $state.Done = $true
                    if (-not $state.Asked) { & $global:DotfilesUpdateScript | Out-Null }
                }
            } catch { $state.Done = $true }
        }
        & $global:DotfilesInnerPrompt
    }
}

if ($Start) {
    Start-DotfilesFetch
} elseif ($Watch) {
    Install-DotfilesPromptWatcher -AlreadyAsked ([bool](Invoke-DotfilesCheck))
} else {
    # Out-Null, not a bare call: Invoke-DotfilesCheck returns whether it put
    # anything on screen, which is for -Watch to consume. Emitted here it just
    # prints "True" under the message it is reporting on.
    Invoke-DotfilesCheck | Out-Null
}
