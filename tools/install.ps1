$ErrorActionPreference = "Stop"

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
			Warn "Install the dependencies and then try again..."
			Say "bye."
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
	if (Test-Path dotfiles) {
		Remove-Item dotfiles -Recurse -Force
	}

	git clone https://github.com/kidchenko/dotfiles.git
}

function Run-Setup () {
    Say
    Say "Running setup"
    Push-Location ./dotfiles
    & ./setup.ps1
    Pop-Location
}

function Main {
	Say "Installing dotfiles at ./dotfiles"

	CheckDeps git, choco, juca
	InstallDeps choco, juca
	Clone
    Run-Setup
}

Main
