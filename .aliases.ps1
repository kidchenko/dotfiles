function GoTo {
    cd ..
}

function Cloud {
    cd ~/Documents/Dropbox
}

function Downloads {
    cd ~/Downloads
}

function Kidchenko {
    cd ~/kidchenko
}

function Playground {
    cd "~/kidchenko/playground"
}

function Thoughtworks {
    cd ~/thoughtworks
}

function Reload-Profile {
    . Update-Profile
}

function Update-Profile {
    $profiles = @(
        $Profile.AllUsersAllHosts,
        $Profile.AllUsersCurrentHost,
        $Profile.CurrentUserAllHosts,
        $Profile.CurrentUserCurrentHost
    )

    foreach ($profile in $profiles) {
        if (Test-Path $profile) {
            Write-Output "Running $profile"
            . $profile
        }
    }
}

function Get-Profile {
    Write-Output $PROFILE
    cat $PROFILE
}

function Find-Text {
    Get-ChildItem -Recurse -Force | Select-String $args[0] -List
}

function List-All {
	Get-ChildItem -Force
}

function List-Directory {
	Get-ChildItem -Directory
}

function List-Hidden {
	Get-ChildItem -Hidden
}

function Get-Week {
    Get-Date -UFormat %V
}

function Run-Update {
    if (!($IsMacOS)) {
        choco.exe upgrade all -y;
    }
}

# WinMac compatibility

# Find aliases
##
###
if(!(Get-Command grep -ErrorAction SilentlyContinue)) {
    Set-Alias grep Find-Text
}

###
##
# End of WinMac compatibility

# Easier navigation:
Set-Alias -Force ".." GoTo

# Shortcuts
Set-Alias dl Downloads
Set-Alias ko Kidchenko
Set-Alias tw Thoughtworks
# Set-Alias play Playground

### Git aliases

# G for git
Set-Alias g git

function GitPush {
    git push
}

# Gps in Pwershell is alias for GetProcess
if (Test-Path alias:gps) {
    if ($Host.Version.Major -gt 6) {
        Remove-Alias -Name gps -Force
    } else {
        Remove-Item alias:gps -Force
    }
}

Set-Alias gps GitPush

Set-Alias reload Reload-Profile

Set-Alias profile Get-Profile

# List files
Set-Alias l ls

# List all files
Set-Alias la List-All

# List only directories
Set-Alias lsd List-Directory

# List only hidden files
Set-Alias lsh List-Hidden

# Get week number
Set-Alias week Get-Week

# Get current date
Set-Alias today Get-Date

# Update Choco/Homebrew
Set-Alias update Run-Update

# Brave
if ($IsMacOS) {
    function Open-Brave { open -n '/Applications/Brave Browser.app' }
    Set-Alias brave Open-Brave
} else {
    Set-Alias brave "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe"
}

# IP Aliases
if ($IsMacOS) {
    function Get-LocalIp { ipconfig getifaddr en0 }
    Set-Alias localip Get-LocalIp
} else {
    function Get-LocalIp { (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Ethernet*).IPAddress }
    Set-Alias localip Get-LocalIp
    Set-Alias ip Get-LocalIp
}

# todo flush / clean up
# end todo

# Alias to generate md5 from string input
if(!(Get-Command md5 -ErrorAction SilentlyContinue)) {
    function Get-Md5($value) {
        ([System.BitConverter]::ToString((New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider).ComputeHash((New-Object -TypeName System.Text.UTF8Encoding).GetBytes($value)))).Replace("-","").ToLower()
      }
    Set-Alias md5 Get-Md5
}

# Alias to generate sha1 from string input
if(!(Get-Command sha1 -ErrorAction SilentlyContinue)) {
    function Get-Sha1($value) {
        ([System.BitConverter]::ToString((New-Object -TypeName System.Security.Cryptography.SHA1CryptoServiceProvider).ComputeHash((New-Object -TypeName System.Text.UTF8Encoding).GetBytes($value)))).Replace("-","")
      }
    Set-Alias sha1 Get-Sha1
}

# Alias to generate sha256 from string input
if(!(Get-Command sha256 -ErrorAction SilentlyContinue)) {
    function Get-Sha256($value) {
        ([System.BitConverter]::ToString((New-Object -TypeName System.Security.Cryptography.SHA256CryptoServiceProvider).ComputeHash((New-Object -TypeName System.Text.UTF8Encoding).GetBytes($value)))).Replace("-","")
      }
    Set-Alias sha256 Get-Sha256
}

# PATH
if ($IsMacOS) {
    function Write-Path { $Env:PATH.Split(":") }
    Set-Alias path Write-Path
} else {
    function Write-Path { $Env:PATH.Split(";") }
    Set-Alias path Write-Path
}

Set-Alias open ii

Set-Alias jit git
