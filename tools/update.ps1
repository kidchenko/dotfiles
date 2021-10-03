# Default settings
$REPO="kidchenko/dotfiles"
$DOTFILES_DIR="~/.$REPO"

function Invoke-Update {
    Write-Host "[dotfiles] New version available."
    $reply = Read-Host -Prompt "[dotfiles] Would you like to update? [y/n]"
    if (($reply  -match "[yY]")) {
        Write-Host "[dotfiles] Updating..."
        Write-Host
        git pull -r
        Pop-Location
        Write-Host "Ready to go!"
        Write-Host
        . "$DOTFILES_DIR/setup.ps1" # script ends here
    }
}

function Main () {
    Write-Host
    Push-Location $DOTFILES_DIR
    $fetch=$(git fetch --dry-run 2>&1)
    if ($fetch) {
        Invoke-Update
    }
    else {
        Pop-Location
        Write-Host "[dotfiles] Using last version."
        Write-Host
    }
}

Main
