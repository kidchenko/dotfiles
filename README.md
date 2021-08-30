# dotfiles
🔧💻  kidchenko's `.files` macOS / Windows - including ~/.macos, ~/.gitconfig, etc.

# Install

## Mac

`sh -c "$(curl -fsSL https://raw.github.com/kidchenko/dotfiles/master/tools/install.sh)"`


## Windows

`Set-ExecutionPolicy Bypass -Scope Process -Force`
`[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072`

`iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/kidchenko/dotfiles/master/tools/install.ps1'))`
