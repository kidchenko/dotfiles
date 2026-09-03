#Requires -Version 5.1
<#
.SYNOPSIS
    Install system packages with Chocolatey - the Windows counterpart of the Brewfile.

.DESCRIPTION
    Mirrors the sections of the repository Brewfile. Each entry below has a
    matching brew/cask line, or a comment explaining why there is no Windows
    equivalent, so the two lists can be diffed by eye.

    Behaviour notes (all of which the previous version got wrong):

      * Requires administrator. Chocolatey cannot write to its lib directory
        otherwise, and previously every install failed silently.
      * Idempotent. Already-installed packages are skipped, so re-running is
        fast instead of reinstalling ~80 packages.
      * Failures are collected and reported at the end rather than scrolling
        past unnoticed; the exit code reflects them.
      * allowGlobalConfirmation is restored in a finally block, so a mid-run
        failure cannot leave the machine globally auto-confirming.

    A few packages come from winget instead of Chocolatey, noted inline - the
    Chocolatey build is stale or absent for those.

.PARAMETER DryRun
    List what would be installed without changing anything.

.PARAMETER Only
    Install a single section (e.g. -Only Terminals). Case-insensitive.
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$Only
)

$ErrorActionPreference = 'Continue'

$script:Installed = 0
$script:Skipped   = 0
$script:Failed    = @()
$script:Missing   = @()

function Say([string]$m)  { Write-Host "[choco] $m" -ForegroundColor Green }
function Head([string]$m) { Write-Host ""; Write-Host "== $m" -ForegroundColor Cyan }
function Warn([string]$m) { Write-Host "[choco] $m" -ForegroundColor Yellow }
function Fail([string]$m) { Write-Host "[choco] ERROR: $m" -ForegroundColor Red; exit 1 }

function Test-Administrator {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    return (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

# --- Preconditions --------------------------------------------------------

if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Fail "Chocolatey not installed. Run tools/bootstrap.ps1 first."
}

if (-not $DryRun -and -not (Test-Administrator)) {
    Fail "Administrator rights required. Run: dotfiles packages (it elevates for you)"
}

# One query up front rather than one per package - `choco list` is slow.
$script:Present = @{}
foreach ($line in (choco list --limit-output 2>$null)) {
    if ($line -match '^([^|]+)\|') { $script:Present[$matches[1].ToLower()] = $true }
}
Say "$($script:Present.Count) package(s) already installed"

# --- Install helpers ------------------------------------------------------

function Install-Pkg {
    param(
        [Parameter(Mandatory)][string]$Name,
        [string]$Because = '',
        [string]$Winget  = '',   # use winget instead (stale/absent on choco)
        [ValidateSet('winget', 'msstore')]
        [string]$Source  = 'winget',
        [string]$Params  = ''
    )

    # Presence has to be checked against whichever store owns the package.
    # `choco list` knows nothing about winget/Store installs, so checking it
    # for a Store app would reinstall it on every run.
    if ($Winget) {
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget list --id $Winget --exact --source $Source 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) { $script:Skipped++; return }
        }
    }
    elseif ($script:Present.ContainsKey($Name.ToLower())) {
        $script:Skipped++
        return
    }

    $via = if ($Winget) { "${Source}:$Winget" } else { "choco:$Name" }

    if ($DryRun) {
        Write-Host ("    would install {0,-28} {1}" -f $Name, $via) -ForegroundColor DarkGray
        $script:Installed++
        return
    }

    Write-Host ("    {0,-28} " -f $Name) -NoNewline

    if ($Winget) {
        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
            Write-Host "skipped (winget unavailable)" -ForegroundColor Yellow
            $script:Failed += "$Name (winget unavailable)"
            return
        }
        winget install --id $Winget --exact --source $Source --silent `
            --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
    } else {
        $args = @('install', $Name, '-y', '--no-progress', '--limit-output')
        if ($Params) { $args += @('--params', $Params) }
        & choco @args 2>&1 | Out-Null
    }

    if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 1641 -or $LASTEXITCODE -eq 3010) {
        Write-Host "ok" -ForegroundColor Green
        $script:Installed++
    } else {
        Write-Host "FAILED (exit $LASTEXITCODE)" -ForegroundColor Red
        $script:Failed += $Name
    }
}

# Packages with a Brewfile entry but no Chocolatey/winget equivalent. Recorded
# and reported so the gap stays visible instead of being silently dropped.
function Note-Missing {
    param([string]$Brew, [string]$Alternative)
    $script:Missing += "$Brew -> $Alternative"
}

function Want([string]$Section) {
    if (-not $Only) { return $true }
    return ($Section -like "*$Only*")
}

# --- Sections (mirroring the Brewfile) ------------------------------------

try {
    if (-not $DryRun) { choco feature enable -n=allowGlobalConfirmation | Out-Null }

    if (Want 'CLI') {
        Head "CLI Tools"
        Install-Pkg curl;  Install-Pkg wget;  Install-Pkg vim
        Install-Pkg grep;  Install-Pkg sed;   Install-Pkg tree; Install-Pkg ack
        Install-Pkg git;   Install-Pkg git-lfs
        Install-Pkg gpg4win -Because 'brew "gnupg"'
        Install-Pkg openssh
        # sudo for Windows. Elevates a single command in place instead of
        # spawning a separate elevated window and losing shell context.
        Install-Pkg gsudo -Because 'no macOS equivalent needed - sudo is built in there'
        # bash, zsh, coreutils, findutils, moreutils, gnu-sed: provided by Git for Windows
        # tmux, watch: no meaningful Windows equivalent
    }

    if (Want 'Modern') {
        Head "Modern CLI replacements"
        Install-Pkg lsd; Install-Pkg bat; Install-Pkg fzf; Install-Pkg jq; Install-Pkg yq
        Install-Pkg ripgrep; Install-Pkg fd
        Install-Pkg tldr    -Because 'brew "tldr"'
        Install-Pkg delta   -Because 'brew "delta"'
        # bottom is the htop equivalent - Windows does have one after all.
        Install-Pkg bottom    -Because 'brew "htop"'
        Install-Pkg zoxide    -Because 'brew "z" - smarter cd, same idea'
        Install-Pkg dust      -Because 'disk usage, du replacement'
        Install-Pkg procs     -Because 'ps replacement'
        Install-Pkg sd        -Because 'sed replacement for find/replace'
        Install-Pkg hyperfine -Because 'command benchmarking'
        Install-Pkg glow      -Because 'markdown rendering in the terminal'
    }

    if (Want 'Development') {
        Head "Development tools"
        Install-Pkg chezmoi; Install-Pkg gh; Install-Pkg go; Install-Pkg nodejs -Because 'brew "node"'
        Install-Pkg nvm; Install-Pkg yarn
        # brew "z": the directory jumper is the `z` PowerShell module, installed by bootstrap.ps1
        Install-Pkg pnpm       -Because 'brew "pnpm"'
        Install-Pkg shellcheck; Install-Pkg terraform
        Install-Pkg direnv     -Because 'brew "direnv"'
        Install-Pkg act-cli    -Because 'brew "act"'
        Install-Pkg dotnet-sdk; Install-Pkg python; Install-Pkg openjdk
        Install-Pkg make; Install-Pkg cmake
        # uv is a fast pip/pipx replacement and the easiest route to the two
        # Python tools below, which have no Chocolatey package of their own.
        Install-Pkg uv -Because 'fast Python package/tool manager'
        Note-Missing 'pre-commit' 'uv tool install pre-commit'
    }

    if (Want 'Languages') {
        Head "Languages & runtimes"
        Install-Pkg ruby
        Install-Pkg pyenv-win -Because 'brew "pyenv"'
        Note-Missing 'poetry' 'uv tool install poetry'
    }

    if (Want 'Cloud') {
        Head "Cloud & DevOps"
        Install-Pkg azure-cli; Install-Pkg awscli
        Install-Pkg flyctl   -Because 'brew "flyctl"'
        Install-Pkg graphviz
        Install-Pkg rclone   -Because 'brew "rclone"'
    }

    if (Want 'Kubernetes') {
        Head "Kubernetes"
        Install-Pkg kubernetes-cli  -Because 'brew "kubectl"'
        Install-Pkg k9s             -Because 'brew "k9s"'
        Install-Pkg kubernetes-helm -Because 'brew "helm"'
    }

    if (Want 'Security') {
        Head "Security"
        Install-Pkg nmap
        Install-Pkg 1password-cli -Because 'cask "1password-cli" - needed by dotfiles ssh'
        Install-Pkg wireshark
    }

    if (Want 'CLIapps') {
        Head "CLI apps"
        Install-Pkg gemini-cli -Because 'brew "gemini-cli"'
        Install-Pkg stripe-cli
        Install-Pkg lazygit    -Because 'brew "lazygit"'
        Install-Pkg neovim     -Because 'brew "neovim"'
        Install-Pkg powershell-core -Because 'brew "powershell" / cask "powershell"'
        Install-Pkg oh-my-posh -Because 'prompt engine used by login.ps1'
        Note-Missing 'jira-cli' 'go install github.com/ankitpokhrel/jira-cli/cmd/jira@latest'
        # mas, dockutil: macOS-only
    }

    if (Want 'Media') {
        Head "Media processing"
        Install-Pkg ffmpeg -Because 'brew "ffmpeg"'
        Install-Pkg imagemagick
    }

    if (Want 'IDE') {
        Head "Development IDEs & editors"
        Install-Pkg vscode -Because 'cask "visual-studio-code"'
        Install-Pkg jetbrainstoolbox -Because 'cask "jetbrains-toolbox", and cask "rider" via the toolbox'
        Install-Pkg docker-desktop
        Install-Pkg cursoride -Because 'cask "cursor"'
    }

    if (Want 'Terminals') {
        Head "Terminals"
        Install-Pkg microsoft-windows-terminal
        Install-Pkg wezterm -Because 'cask "wezterm"'
        Install-Pkg hyper
        # iterm2: macOS-only
    }

    if (Want 'Browsers') {
        Head "Browsers"
        Install-Pkg brave -Because 'cask "brave-browser"'
        Install-Pkg googlechrome -Because 'cask "google-chrome"'
        Install-Pkg firefox -Because 'cask "firefox"'
    }

    if (Want 'AI') {
        Head "AI tools"
        # The Chocolatey `claude` build lags well behind winget's.
        Install-Pkg claude      -Winget 'Anthropic.Claude'     -Because 'cask "claude"'
        Install-Pkg claude-code -Because 'cask "claude-code"'
        Install-Pkg chatgpt     -Because 'cask "chatgpt"'
    }

    if (Want 'Database') {
        Head "Database"
        Install-Pkg postgresql -Because 'brew "postgresql@16"'
        Install-Pkg mysql-cli  -Because 'brew "mysql-client"'
        Install-Pkg redis
        Install-Pkg dbeaver    -Because 'cask "dbeaver-community"'
        Install-Pkg azure-data-studio
        Install-Pkg sql-server-management-studio
    }

    if (Want 'Productivity') {
        Head "Productivity"
        Install-Pkg 1password; Install-Pkg slack; Install-Pkg notion
        Install-Pkg postman; Install-Pkg discord
        Install-Pkg grammarly-for-windows -Because 'cask "grammarly-desktop"'
        Install-Pkg powertoys -Because 'covers cask "rectangle" (FancyZones) and cask "raycast" (Run)'
        Install-Pkg whatsapp -Winget '9NKSQGP7F2NH' -Source msstore -Because 'cask "whatsapp"'
        Note-Missing 'wakatime' 'editor extension, not a standalone package'
        # alt-tab: macOS-only
    }

    if (Want 'Utilities') {
        Head "Utilities"
        Install-Pkg googledrive -Because 'cask "google-drive"'
        Install-Pkg flux        -Because 'cask "flux-app"'
        Install-Pkg rescuetime
        # Store build, not choco: `choco install spotify` lays down the
        # standalone installer, which coexists with (rather than replaces) a
        # Store copy and leaves two Spotifys on the machine.
        Install-Pkg spotify -Winget '9NCBCSZSJRSB' -Source msstore -Because 'cask "spotify"'
        Install-Pkg 7zip; Install-Pkg everything; Install-Pkg windirstat
        Install-Pkg autohotkey; Install-Pkg vlc; Install-Pkg screentogif
        # Process Explorer, Autoruns, TCPView, ZoomIt
        Install-Pkg sysinternals -Because 'no single macOS equivalent'
    }

    if (Want 'Fonts') {
        Head "Fonts"
        Install-Pkg nerd-fonts-Hack     -Because 'cask "font-hack-nerd-font"'
        Install-Pkg nerd-fonts-FiraCode -Because 'cask "font-fira-code-nerd-font"'
        Install-Pkg nerd-fonts-FiraMono -Because 'cask "font-fira-mono-nerd-font"'
        Install-Pkg nerd-fonts-Meslo    -Because 'cask "font-meslo-lg-nerd-font"'
    }
}
finally {
    # Must run even on failure - otherwise the machine is left globally
    # auto-confirming every future choco command.
    if (-not $DryRun) { choco feature disable -n=allowGlobalConfirmation | Out-Null }
}

# --- Summary --------------------------------------------------------------

Write-Host ""
Write-Host ("-" * 52) -ForegroundColor DarkGray
if ($DryRun) {
    Say "Dry run: $($script:Installed) would install, $($script:Skipped) already present"
} else {
    Say "$($script:Installed) installed, $($script:Skipped) already present, $($script:Failed.Count) failed"
}

if ($script:Failed.Count -gt 0) {
    Write-Host ""
    Warn "Failed:"
    foreach ($f in $script:Failed) { Write-Host "    $f" -ForegroundColor Red }
}

if ($script:Missing.Count -gt 0) {
    Write-Host ""
    Warn "In the Brewfile with no Chocolatey equivalent - install manually:"
    foreach ($m in $script:Missing) { Write-Host "    $m" -ForegroundColor DarkGray }
}

Write-Host ""
if ($script:Failed.Count -gt 0) { exit 1 }
exit 0
