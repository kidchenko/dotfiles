$ErrorActionPreference = "Stop"

$REPO="kidchenko/dotfiles"
$DOTFILES_DIR="~/.$REPO"

function CopyProfile() {
	if (!(Test-Path $PROFILE)) {
		Write-Host "creating $PROFILE"
        New-Item -Path $PROFILE -ItemType File -Force
	}

	$dest = Split-Path $PROFILE

    # Copy-Item ./tools/update.ps1 -Destination ~/.kidchenko/dotfiles/tools/update.ps1 -Force
	Copy-Item $DOTFILES_DIR/profile.ps1 -Destination $PROFILE -Force
	Copy-Item $DOTFILES_DIR/.login.ps1 -Destination "~/.login.ps1" -Force
	Copy-Item $DOTFILES_DIR/.modules.ps1 -Destination "~/.modules.ps1" -Force
	Copy-Item $DOTFILES_DIR/.aliases.ps1 -Destination "~/.aliases.ps1" -Force
    Copy-Item $DOTFILES_DIR/.gitconfig -Destination ~/.gitconfig -Force
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
