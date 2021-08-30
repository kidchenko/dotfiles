Install-PackageProvider -Name NuGet -Force

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

Install-Module -Name PowerShellGet -Force

Update-Module -Name PowerShellGet

Install-Module -Name z

Install-Module -Name posh-git

Install-Module -Name oh-my-posh

Get-Module -ListAvailable PowerShellGet
