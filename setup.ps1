[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
-Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force


Install-PackageProvider -Name NuGet -Force

Install-Module -Name PowerShellGet -Force

Update-Module -Name PowerShellGet

Install-Module -Name z

Install-Module -Name posh-git

Install-Module -Name oh-my-posh

Get-Module -ListAvailable PowerShellGet

#Get-InstalledModule
