function Say ([string]$message) {
	Write-Host $message
}
function Warn([string]$message) {
	Write-Warning $message
}

function IsCommand([string]$cmd) {
	return which $cmd
}

function CheckDeps([string[]]$deps) {
	foreach ($cmd in $deps) {
		Say "checking if $cmd is installed"
		if (!(IsCommand $cmd)) {
			Warn "$cmd is not found"
		}
	}
}

function InstallDeps ([string[]]$deps) {
	Say "installing..."
	foreach ($cmd in $deps) {
		Say "installing $cmd"
	}
}

function Main {
	Say "hello world"
	Say "checking dependencies..."
	CheckDeps git, choco, juca
	InstallDeps choco, juca
}

Main
