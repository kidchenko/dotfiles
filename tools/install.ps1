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
	Say "checking dependencies..."
	foreach ($cmd in $deps) {
		Say "checking if $cmd is installed"
		if (!(IsCommand $cmd)) {
			Warn "$cmd is not found"
			$notFound++
		}
	}
	if ($notFound -gt 0) {
		Warn "The dependencies listed above are required to use $SCRIPTNAME"
		$reply = Ask "Do you wanna to install? [y/n]"
		if (!($reply  -match "[yY]")) {
			# Highway to the danger zone
			Warn "install the dependencies and then try again..."
			say "bye."
			exit
		}
	}
}

function InstallDeps ([string[]]$deps) {
	Say
	Say "installing deps..."
	foreach ($cmd in $deps) {
		Say "installing $cmd"
	}
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
	Say "hello world"

	CheckDeps git, choco, juca
	InstallDeps choco, juca
	Clone
    Run-Setup
}

Main
