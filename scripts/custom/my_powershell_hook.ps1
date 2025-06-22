#Requires -Version 5.1
Write-Host "[CUSTOM POWERSHELL HOOK] Hello from my_powershell_hook.ps1!"
Write-Host "[CUSTOM POWERSHELL HOOK] Current directory: $(Get-Location)"
Write-Host "[CUSTOM POWERSHELL HOOK] User: $env:USERNAME"
# Example: Create a file
New-Item -Path "$env:USERPROFILE\powershell_hook_was_here.txt" -ItemType File -Force | Out-Null
Write-Host "[CUSTOM POWERSHELL HOOK] Created $env:USERPROFILE\powershell_hook_was_here.txt"
