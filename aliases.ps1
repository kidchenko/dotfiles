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
    @(
        $Profile.AllUsersAllHosts,
        $Profile.AllUsersCurrentHost,
        $Profile.CurrentUserAllHosts,
        $Profile.CurrentUserCurrentHost
    ) | % {
        if (Test-Path $_) {
            Write-Output "Running $_"
            . $_
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
Set-Alias g git
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

Set-Alias today Get-Date

Set-Alias update Run-Update
