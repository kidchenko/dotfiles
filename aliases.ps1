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

# List all files
Set-Alias la Get-ChildItem -Force

# todo find aliases

