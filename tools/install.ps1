$ErrorActionPreference = "Stop"
if ($env:HOME) {
    $BASE_DIR=$env:HOME
} else {
    $BASE_DIR=$env:HOMEPATH
}
$REPO="kidchenko/dotfiles"
$DOTFILES_DIR="$BASE_DIR/.$REPO"
$REMOTE="https://github.com/$REPO.git"

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
	if ($IsMacOS -or $IsLinux) {
		return which $cmd
	}

	return where.exe $cmd
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
		Say "Installing dependency: $dep."
	}
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
        Say "Fail to clone dotfiles."
        Read-Host 'Press Enter to exit…'
        throw "Error cloning dotfiles"
    }
}

function Invoke-Setup () {
    Say "Running setup."
    Say
    & "$DOTFILES_DIR/setup.ps1"
}

function Main {
	Say "Installing dotfiles at $DOTFILES_DIR"

	CheckDeps git, choco, juca
	InstallDeps choco, juca
	Clone
    Invoke-Setup
}

Main
