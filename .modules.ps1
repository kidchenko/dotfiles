Import-Module posh-git
Import-Module PSColor

if (Get-Module -ListAvailable -Name PSReadLine) {
}
else {
    Import-Module PSReadLine
}

if (!($IsMacOS)) {
    Import-Module Pscx
}

Set-PSReadLineOption -PredictionSource History
