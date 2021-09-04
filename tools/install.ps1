function Warn([string]$message) {
	Write-Warning $message
}

function IsCommand([string]$cmd) {
	return which $cmd
}

function CheckDeps([string[]]$deps) {
	foreach ($cmd in $deps) {
		Write-Host "checking if $cmd is installed"
		if (!(IsCommand $cmd)) {
			Warn "$cmd is not found"
		}
	}
}

function InstallDeps ([string[]]$deps) {
	"installing..."
	foreach ($cmd in $deps) {
		Write-Host "installing $cmd"
	}
}

function Main {
	"hello world"
	Write-Output "checking dependencies..."
	CheckDeps git, choco, juca
	InstallDeps choco, juca
}

Main
