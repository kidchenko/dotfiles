Install-Module -Name PowerShellGet -Force

Install-Module -Name z -AllowClobber

Install-Module -Name posh-git

Install-Module -Name oh-my-posh

Install-Module -Name PSColor

Install-Module -Name PSReadLine -RequiredVersion 2.1.0 -Force

if (!($IsMacOS)) {
    Install-Module -Name Pscx -RequiredVersion 3.3.2 -AllowClobber
}

Get-Module -ListAvailable PowerShellGet

Get-InstalledModule
