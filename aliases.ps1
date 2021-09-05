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

# Easier navigation: ..
Set-Alias -Force ".." GoTo

# Shortcuts
Set-Alias "d" Cloud
Set-Alias dl Downloads
Set-Alias ko Kidchenko
Set-Alias tw Thoughtworks
# Set-Alias play Playground

Set-Alias g git
# Set-Alias profile="cat ~/.zshrc"
