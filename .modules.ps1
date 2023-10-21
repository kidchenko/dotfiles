#Import-Module posh-git
# Import-Module PSColor
Import-Module Terminal-Icons
Import-Module PSReadLine -Force

if (Get-Module -ListAvailable -Name PSReadLine) {
}
else {
    Import-Module PSReadLine
}

if (!($IsMacOS)) {
    Import-Module Pscx
}

Set-PSReadLineOption -PredictionSource History
# Not Working
# Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows
