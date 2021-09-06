$ErrorActionPreference = "Stop"

# use tls 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

function CopyProfile() {
	Write-Host "copy $PROFILE"
	if (!(Test-Path $PROFILE)) {
		New-Item -Path $PROFILE -ItemType File -Force
	}

	Copy-Item ./profile.ps1 -Destination $PROFILE -Force
}

function Main () {
    CopyProfile
    . $PROFILE
}

Main
