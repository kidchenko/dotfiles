$REPO="kidchenko/dotfiles"
$DOTFILES_DIR="~/.$REPO"

$Hour = (Get-Date).Hour
$Name = "Jose"
$Theme = "robbyrussel.omp.json"

if (Test-Path "$DOTFILES_DIR/tools/update.ps1") {
    . "$DOTFILES_DIR/tools/update.ps1"
}

If ($Hour -lt 12) {"Good Morning $Name!"}

ElseIf ($Hour -gt 16) {"Good Evening $Name!"}

Else {"Good Afternoon $Name!"; }

# Allow remote execution
if (!($IsMacOS)) {
    Set-ExecutionPolicy Bypass -Scope CurrentUser -Force -ErrorAction SilentlyContinue;
}

# use tls 1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;

oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/$Theme" | Invoke-Expression