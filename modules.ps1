Import-Module posh-git
Import-Module oh-my-posh
Import-Module PSColor
Import-Module PSReadLine -PassThru

if (!($IsMacOS)) {
    Import-Module Pscx
}

Set-PSReadLineOption -PredictionSource History
