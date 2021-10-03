# Default settings
$REPO="kidchenko/dotfiles"
$DOTFILES_DIR="~/.$REPO"

Write-Output "I am update"

function Main () {
    Write-Host
    pushd $DOTFILES_DIR >/dev/null
    $fetch=$(git fetch --dry-run 2>&1)
    if ($fetch) {
        Write-Host "fecht";
    }

    popd
}

Main
