$ErrorActionPreference = "Stop"
if ($env:HOME) {
    $BASE_DIR=$env:HOME
} else {
    $BASE_DIR=$env:HOMEPATH
}
$REPO="kidchenko/dotfiles"
$DOTFILES_DIR="$BASE_DIR/.$REPO"
$REMOTE="https://github.com/$REPO.git"

# OS detection functions (copied from setup.ps1)
function Get-OSType-Install {
    if ($IsWindows) { return "windows" }
    elseif ($IsMacOS) { return "macos" }
    elseif ($IsLinux) { return "linux" }
    else { return "unknown" }
}

function Test-IsMacOS-Install { return $IsMacOS }
function Test-IsLinux-Install { return $IsLinux }
function Test-IsWindows-Install { return $IsWindows }
# End OS detection functions

function Say ([string]$message) {
	Write-Host $message
}

function Ask ([string] $message) {
	Say
	Read-Host -Prompt $message
}

function Warn([string]$message) {
	Say
	Write-Warning $message
    Say
}

function IsCommand([string]$cmd) {
	# In PowerShell 7+, Get-Command can find executables.
    # For broader compatibility, especially on Windows PowerShell 5.1:
	if (Test-IsWindows-Install) {
        # where.exe is reliable on Windows for finding .exe, .cmd, .bat etc. in PATH
        return (where.exe $cmd 2>$null)
	} else {
        # For macOS/Linux, 'command -v' or 'which' are typical
        # 'command -v' is generally preferred over 'which'
        # Using Get-Command as it's PowerShell idiomatic and works for functions/aliases too
        return (Get-Command $cmd -ErrorAction SilentlyContinue)
	}
}

function CheckDeps([string[]]$deps) {
	$notFound = 0
	Say
	Say "Checking dependencies..."
    Say
	foreach ($cmd in $deps) {
		Say "Checking if $cmd is installed."
		if (!(IsCommand $cmd)) {
			warn "$cmd is required and is not found."
			$notFound++
		}
	}
	if ($notFound -gt 0) {
		Warn "The dependencies listed above are required to install and use this project."
        Say "I can install the required dependencies for you."
		$reply = Ask "Do you wanna to install? [y/n]"
		if (!($reply  -match "[yY]")) {
			# Highway to the danger zone
			Warn "Install the required dependencies and then try again..."
			Say "Bye."
			exit
		}
	}
}

function InstallDeps ([string[]]$deps) {
	Say
	Say "Installing dependencies..."
    Say
	foreach ($dep in $deps) {
		if ($dep -eq "choco") {
			Install-Choco
		} else {
			Install-DotFileDependency($dep)
		}
	}
    Say
}

function Install-DotFileDependency([string] $dep) {
	Say "Installing dependency: $dep."
	choco install $dep -y
}

function Install-Choco(){
	Say "Installing choco: https://chocolatey.org/install#individual"

	Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
	
	Say "choco installed."
	Say
}

function Clone () {
    Say "Cloning dotfiles..."
    Say
	
	if (Test-Path $DOTFILES_DIR) {
		Remove-Item $DOTFILES_DIR -Recurse -Force
	}
    try {
    	git clone $REMOTE $DOTFILES_DIR
        Say
    }
    catch {
        Say "Fail to clone the dotfiles, please check the dependencies and try again"
        throw "Error cloning dotfiles"
        Read-Host 'Press Enter to exit…'
    }
}

function Invoke-Setup () {
    Say "Running setup."
    Say
    & "$DOTFILES_DIR/setup.ps1"
}

function Install-DotFilesPsGetModules () {
	Say "> Running psget.ps1"
	& "$DOTFILES_DIR/psget.ps1"
}

function Main {
	Say "Installing dotfiles at $DOTFILES_DIR"
    Say "Determined OS Type: $(Get-OSType-Install)"

	CheckDeps choco, git, juca
	InstallDeps choco, git #, juca
	Install-DotFilesPsGetModules

	Install-Chezmoi

	Clone

    Invoke-Setup
}

function Install-Chezmoi {
	Say "Installing chezmoi..."
	Say
	if (!(IsCommand "chezmoi")) {
		Say "Installing chezmoi using Chocolatey..."
		choco install chezmoi -y
	} else {
		Say "chezmoi is already installed."
	}
	Say
}

Main
