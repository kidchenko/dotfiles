#Import-Module posh-git
# Import-Module PSColor
Import-Module Terminal-Icons

if (Get-Module -ListAvailable -Name PSReadLine) {
}
else {
    Import-Module PSReadLine
}

if (!($IsMacOS)) {
    Import-Module Pscx
}

Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows
