$ErrorActionPreference = "Stop"

# use tls 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

function CopyProfile() {
	@(
		$Profile.AllUsersAllHosts,
		$Profile.AllUsersCurrentHost,
		$Profile.CurrentUserAllHosts,
		$Profile.CurrentUserCurrentHost
	) | % {
		if (Test-Path $_) {
			Write-Host "copy $_"
			if (!(Test-Path $_)) {
				New-Item -Path $_ -ItemType File -Force
			}

			$dest = Split-Path $_

			Copy-Item ./profile.ps1 -Destination $_ -Force
			Copy-Item ./modules.ps1 -Destination "$dest/modules.ps1" -Force
			Copy-Item ./aliases.ps1 -Destination "$dest/aliases.ps1" -Force

			Write-Output "Reload $_"
			. $_
		}
	}
}

function Main () {
    CopyProfile
}

Main
