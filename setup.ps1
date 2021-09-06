$ErrorActionPreference = "Stop"

# use tls 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

function CopyProfile() {
	if (!(Test-Path $PROFILE)) {
		Write-Host "creating $PROFILE"
	}

	New-Item -Path $PROFILE -ItemType File -Force

	$dest = Split-Path $PROFILE

	Copy-Item ./profile.ps1 -Destination $PROFILE -Force
	Copy-Item ./modules.ps1 -Destination "$dest/modules.ps1" -Force
	Copy-Item ./aliases.ps1 -Destination "$dest/aliases.ps1" -Force


}

function ReloadProfile {
	Write-Output "Reload $PROFILE"
	. $PROFILE
}

function Main () {
	CopyProfile
	ReloadProfile
}

Main
