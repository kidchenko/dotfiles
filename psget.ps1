Install-Module -Name PowerShellGet -Force

Install-Module -Name z -AllowClobber

Install-Module -Name posh-git

# Install-Module -Name PSColor

Install-Module -Name Terminal-Icons

Install-Module -Name PSReadLine -Force -AllowPrerelease -SkipPublisherCheck

if (!($IsMacOS)) {
    Install-Module -Name Pscx -RequiredVersion 3.3.2 -AllowClobber
}
