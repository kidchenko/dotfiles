#!/usr/bin/env bash

# APT package installer for Debian/Ubuntu systems
# This script installs packages equivalent to those in brew.sh for macOS

# Exit on error
set -e

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing sudo time stamp until the script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Update package list
echo "Updating package list..."
sudo apt update

# Upgrade existing packages
echo "Upgrading installed packages..."
sudo apt upgrade -y

# Install essential build tools and dependencies
sudo apt install -y \
    build-essential \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# Install GNU core utilities and tools
echo "Installing GNU utilities..."
sudo apt install -y \
    coreutils \
    moreutils \
    findutils \
    sed \
    grep

# Install shells and completion
echo "Installing shells..."
sudo apt install -y \
    bash \
    bash-completion \
    zsh

# Install essential tools
echo "Installing essential tools..."
sudo apt install -y \
    curl \
    wget \
    git \
    git-lfs \
    gnupg \
    vim \
    openssh-client \
    screen \
    tree

# Install CTF and security tools
echo "Installing security/CTF tools..."
sudo apt install -y \
    aircrack-ng \
    binutils \
    binwalk \
    dex2jar \
    dns2tcp \
    fcrackzip \
    foremost \
    hashcat \
    hydra \
    john \
    nmap \
    socat \
    sqlmap \
    tcpflow \
    tcpreplay \
    tcptrace \
    xpdf \
    xz-utils \
    p7zip-full \
    netcat

# Install other useful packages
echo "Installing useful binaries..."
sudo apt install -y \
    ack \
    imagemagick \
    lua5.4 \
    lynx \
    pigz \
    pv \
    rename \
    rlwrap \
    vbindiff

# Install programming languages and runtimes
echo "Installing programming languages..."
sudo apt install -y \
    ruby \
    ruby-dev \
    php \
    php-cli

# Install jq (JSON processor)
sudo apt install -y jq

# Install graphviz
sudo apt install -y graphviz

# Install ripgrep
echo "Installing ripgrep..."
sudo apt install -y ripgrep

# Install fd-find (fd)
echo "Installing fd-find..."
sudo apt install -y fd-find
# Create symlink for 'fd' command if it doesn't exist
if ! command -v fd &> /dev/null; then
    sudo ln -sf $(which fdfind) /usr/local/bin/fd 2>/dev/null || true
fi

# Install fzf
echo "Installing fzf..."
sudo apt install -y fzf

# Install bat (might be named batcat on Debian/Ubuntu)
echo "Installing bat..."
if apt-cache search --names-only '^bat$' | grep -q '^bat'; then
    sudo apt install -y bat
elif apt-cache search --names-only '^batcat$' | grep -q '^batcat'; then
    sudo apt install -y batcat
    # Create symlink for 'bat' command if it doesn't exist
    if ! command -v bat &> /dev/null && command -v batcat &> /dev/null; then
        sudo ln -sf $(which batcat) /usr/local/bin/bat 2>/dev/null || true
    fi
fi

# Install shellcheck
echo "Installing shellcheck..."
sudo apt install -y shellcheck

# Install z (jump around)
echo "Installing z..."
if [ ! -d "$HOME/.z" ]; then
    git clone https://github.com/rupa/z.git "$HOME/.z"
fi

# Install GitHub CLI
echo "Installing GitHub CLI..."
if ! command -v gh &> /dev/null; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install -y gh
fi

# Install Azure CLI
echo "Installing Azure CLI..."
if ! command -v az &> /dev/null; then
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
fi

# Install Docker
echo "Installing Docker..."
if ! command -v docker &> /dev/null; then
    # Add Docker's official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Add the repository to Apt sources
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Add current user to docker group
    sudo usermod -aG docker $USER
    echo "NOTE: You'll need to log out and back in for docker group membership to take effect"
fi

# Install Node.js and npm via NodeSource
echo "Installing Node.js..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt install -y nodejs
fi

# Install Yarn
echo "Installing Yarn..."
if ! command -v yarn &> /dev/null; then
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
    sudo apt update
    sudo apt install -y yarn
fi

# Install Go
echo "Installing Go..."
if ! command -v go &> /dev/null; then
    GO_VERSION="1.21.5"
    wget "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
    rm "go${GO_VERSION}.linux-amd64.tar.gz"
    echo "NOTE: Add 'export PATH=\$PATH:/usr/local/go/bin' to your shell profile"
fi

# Install Terraform
echo "Installing Terraform..."
if ! command -v terraform &> /dev/null; then
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update
    sudo apt install -y terraform
fi

# Install chezmoi
echo "Installing chezmoi..."
if ! command -v chezmoi &> /dev/null; then
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
fi

# Install yq
echo "Installing yq..."
if ! command -v yq &> /dev/null; then
    YQ_VERSION="v4.40.5"
    wget "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64" -O /tmp/yq
    sudo mv /tmp/yq /usr/local/bin/yq
    sudo chmod +x /usr/local/bin/yq
fi

# Install lsd (LSDeluxe)
echo "Installing lsd..."
if ! command -v lsd &> /dev/null; then
    LSD_VERSION="1.0.0"
    wget "https://github.com/lsd-rs/lsd/releases/download/v${LSD_VERSION}/lsd_${LSD_VERSION}_amd64.deb"
    sudo dpkg -i "lsd_${LSD_VERSION}_amd64.deb"
    rm "lsd_${LSD_VERSION}_amd64.deb"
fi

# Install Tesseract OCR
echo "Installing Tesseract OCR..."
sudo apt install -y tesseract-ocr

# Install PHP Composer
echo "Installing Composer..."
if ! command -v composer &> /dev/null; then
    EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

    if [ "$EXPECTED_CHECKSUM" = "$ACTUAL_CHECKSUM" ]; then
        php composer-setup.php --quiet --install-dir=/usr/local/bin --filename=composer
        RESULT=$?
        rm composer-setup.php
        exit $RESULT
    else
        >&2 echo 'ERROR: Invalid installer checksum for Composer'
        rm composer-setup.php
    fi
fi

# Clean up
echo "Cleaning up..."
sudo apt autoremove -y
sudo apt autoclean

echo ""
echo "==========================================="
echo "APT installation complete!"
echo "==========================================="
echo ""
echo "NOTE: Some tools require additional setup:"
echo "  - Docker: Log out and back in for group membership"
echo "  - Go: Add /usr/local/go/bin to your PATH"
echo "  - NVM: Install manually from https://github.com/nvm-sh/nvm"
echo "  - Some GUI applications may need manual installation"
echo ""
