# Chocolatey package installer for Windows
# This script installs packages equivalent to those in brew.sh for macOS

# Enable global confirmation to avoid prompts
choco feature enable -n=allowGlobalConfirmation

Write-Host "Starting Chocolatey package installation..." -ForegroundColor Green

# Update Chocolatey
Write-Host "`nUpdating Chocolatey..." -ForegroundColor Yellow
choco upgrade chocolatey -y

# ============================================================================
# Development Tools & Runtimes
# ============================================================================
Write-Host "`nInstalling Development Tools..." -ForegroundColor Yellow

choco install git
choco install git-lfs
choco install gh                    # GitHub CLI
choco install dotnet-sdk
choco install nodejs
choco install nvm                   # Node Version Manager
choco install yarn
choco install go
choco install ruby
choco install php
choco install composer              # PHP dependency manager
choco install python
choco install openjdk              # Java

# ============================================================================
# Essential CLI Tools
# ============================================================================
Write-Host "`nInstalling Essential CLI Tools..." -ForegroundColor Yellow

choco install curl
choco install wget
choco install jq                    # JSON processor
choco install yq                    # YAML processor
choco install vim
choco install grep
choco install sed
choco install tree
choco install ack
choco install ripgrep              # Modern grep alternative
choco install fd                   # Modern find alternative
choco install bat                  # Modern cat with syntax highlighting
choco install fzf                  # Fuzzy finder
choco install lsd                  # Modern ls replacement
choco install chezmoi              # Dotfiles manager

# ============================================================================
# Cloud & Infrastructure Tools
# ============================================================================
Write-Host "`nInstalling Cloud & Infrastructure Tools..." -ForegroundColor Yellow

choco install azure-cli
choco install awscli
choco install terraform
choco install docker-desktop
choco install kubernetes-cli       # kubectl

# ============================================================================
# Security & CTF Tools
# ============================================================================
Write-Host "`nInstalling Security Tools..." -ForegroundColor Yellow

choco install nmap
choco install wireshark
choco install gpg4win              # GPG/GnuPG for Windows
choco install openssh

# Note: Many CTF tools from macOS/Linux don't have direct Windows equivalents
# or require WSL (Windows Subsystem for Linux) to run

# ============================================================================
# Build Tools & Utilities
# ============================================================================
Write-Host "`nInstalling Build Tools..." -ForegroundColor Yellow

choco install make
choco install cmake
choco install visualstudio2022buildtools  # Visual Studio Build Tools
choco install shellcheck            # Shell script linter
choco install graphviz

# ============================================================================
# Archive & Compression Tools
# ============================================================================
Write-Host "`nInstalling Archive Tools..." -ForegroundColor Yellow

choco install 7zip
choco install p7zip                 # Command-line 7zip

# ============================================================================
# Productivity & Communication
# ============================================================================
Write-Host "`nInstalling Productivity Apps..." -ForegroundColor Yellow

choco install slack
choco install discord
choco install notion
choco install spotify
choco install grammarly-for-windows

# ============================================================================
# Browsers
# ============================================================================
Write-Host "`nInstalling Browsers..." -ForegroundColor Yellow

choco install brave
choco install googlechrome

# ============================================================================
# Development IDEs & Editors
# ============================================================================
Write-Host "`nInstalling IDEs & Editors..." -ForegroundColor Yellow

choco install vscode
choco install jetbrainstoolbox      # JetBrains Toolbox (manages Rider, IntelliJ, etc.)

# ============================================================================
# Terminals
# ============================================================================
Write-Host "`nInstalling Terminal Applications..." -ForegroundColor Yellow

choco install microsoft-windows-terminal  # Windows Terminal
choco install powershell-core            # PowerShell Core (cross-platform)
choco install hyper                       # Hyper terminal

# ============================================================================
# Database Tools
# ============================================================================
Write-Host "`nInstalling Database Tools..." -ForegroundColor Yellow

choco install dbeaver               # Universal database tool
choco install sql-server-management-studio  # SSMS
choco install mysql.workbench       # MySQL Workbench
choco install azure-data-studio

# ============================================================================
# API Development
# ============================================================================
Write-Host "`nInstalling API Development Tools..." -ForegroundColor Yellow

choco install postman
choco install insomnia-rest-api-client  # Alternative to Postman

# ============================================================================
# System Utilities
# ============================================================================
Write-Host "`nInstalling System Utilities..." -ForegroundColor Yellow

choco install powertoys             # Microsoft PowerToys
choco install 1password             # Password manager
choco install flux                  # Blue light filter
choco install rescuetime           # Time tracking
choco install windirstat           # Disk usage analyzer
choco install everything           # Fast file search
choco install autohotkey           # Automation scripting

# ============================================================================
# Media & Graphics
# ============================================================================
Write-Host "`nInstalling Media Tools..." -ForegroundColor Yellow

choco install screentogif          # Screen recorder to GIF
choco install vlc                  # Media player
choco install imagemagick          # Image manipulation

# ============================================================================
# Documentation & Reading
# ============================================================================
Write-Host "`nInstalling Documentation Tools..." -ForegroundColor Yellow

choco install adobereader          # PDF reader
choco install calibre              # E-book manager

# ============================================================================
# Fonts
# ============================================================================
Write-Host "`nInstalling Fonts..." -ForegroundColor Yellow

# Nerd Fonts for terminal
choco install nerd-fonts-hack
# Alternative: nerd-fonts-cascadiacode, nerd-fonts-firacode

# ============================================================================
# AI Tools
# ============================================================================
Write-Host "`nInstalling AI Tools..." -ForegroundColor Yellow

# Note: Claude desktop and Cursor might not be available via Chocolatey
# Check their official websites for Windows installers:
# - Claude: https://claude.ai
# - Cursor: https://cursor.sh

# ============================================================================
# CLI Productivity Tools
# ============================================================================
Write-Host "`nInstalling CLI Productivity Tools..." -ForegroundColor Yellow

choco install stripe-cli           # Stripe CLI (if available)
# Note: chatgpt-cli, gemini-cli, jira-cli might not be available on Chocolatey
# These may need to be installed via npm, pip, or from GitHub releases

# ============================================================================
# Additional Development Tools
# ============================================================================
Write-Host "`nInstalling Additional Development Tools..." -ForegroundColor Yellow

choco install tesseract            # OCR engine
choco install redis                # Redis server
choco install nginx                # Web server

# ============================================================================
# Cleanup
# ============================================================================
Write-Host "`nCleaning up..." -ForegroundColor Yellow

# Disable global confirmation
choco feature disable -n=allowGlobalConfirmation

Write-Host "`n==========================================" -ForegroundColor Green
Write-Host "Chocolatey installation complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "NOTES:" -ForegroundColor Yellow
Write-Host "  - Some applications may require a system restart" -ForegroundColor White
Write-Host "  - Docker Desktop requires WSL2 to be enabled" -ForegroundColor White
Write-Host "  - Add to PATH manually if needed: Go, Node.js tools, etc." -ForegroundColor White
Write-Host "  - Some AI tools (Claude, Cursor) may need manual installation" -ForegroundColor White
Write-Host "  - CTF/Security tools are limited on Windows - consider using WSL" -ForegroundColor White
Write-Host ""
Write-Host "To install AI CLI tools via npm:" -ForegroundColor Cyan
Write-Host "  npm install -g chatgpt-cli" -ForegroundColor White
Write-Host "  npm install -g @google/generative-ai-cli" -ForegroundColor White
Write-Host ""
