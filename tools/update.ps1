# Default settings
$REPO="kidchenko/dotfiles"
$DOTFILES_DIR="~/.$REPO"

function Invoke-Update {
    Write-Host "[dotfiles] New version available."
    $reply = Read-Host -Prompt "[dotfiles] Would you like to update? [y/n]: "
    if (!($reply  -match "[yY]")) {
        Write-Host "[dotfiles] Updating..."
        Write-Host
        git pull -r
        popd >/dev/null
        Write-Host "Ready to go!"
        Write-Host
        . "$DOTFILES_DIR/setup.ps1" # script ends here
    }
}

function Main () {
    Write-Host
    pushd $DOTFILES_DIR >/dev/null
    $fetch=$(git fetch --dry-run 2>&1)
    if ($fetch) {
        Invoke-Update
    }
    else {
        popd >/dev/null
        Write-Host "[dotfiles] Using last version."
        Write-Host
    }
}

Main
