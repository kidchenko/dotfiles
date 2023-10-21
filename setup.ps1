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

    Copy-Item $DOTFILES_DIR/.hyper.win.js -Destination $Env:AppData/Hyper/.hyper.js
}

function EnsureFolders() {

    if (!(Test-Path "~/lambda3")) {
        Write-Output "~/lambda3 folder does not exist. Creating..."

        mkdir "~/lambda3"

        Write-Output ""
    }

    if (!(Test-Path "~/jetabroad")) {
        Write-Output "~/jetabroad folder does not exist. Creating..."

        mkdir "~/jetabroad"

        Write-Output ""
    }

    if (!(Test-Path "~/thoughtworks")) {
        Write-Output "~/thoughtworks folder does not exist. Creating..."

        mkdir "~/thoughtworks"
        Write-Output ""
    }

    if (!(Test-Path "~/sevenpeaks")) {
        Write-Output "~/sevenpeaks folder does not exist. Creating..."

        mkdir "~/sevenpeaks"
        Write-Output ""
    }

    if (!(Test-Path "~/isho")) {
        Write-Output "~/isho folder does not exist. Creating..."

        mkdir "~/isho"
        Write-Output ""
    }

    if (!(Test-Path "~/kidchenko")) {
        Write-Output "~/kidchenko folder does not exist. Creating..."

        mkdir "~/kidchenko"
        Write-Output ""
    }
}

function ReloadProfile {
	Write-Output "Reload $PROFILE"
	. $PROFILE
}



function Main () {
	CopyProfile
    EnsureFolders
	ReloadProfile
}

Main
