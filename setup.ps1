$ErrorActionPreference = "Stop"

# use tls 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

Install-Module -Name PowerShellGet -Force

Install-Module -Name z

Install-Module -Name posh-git

Install-Module -Name oh-my-posh

Get-Module -ListAvailable PowerShellGet

Get-InstalledModule
