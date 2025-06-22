# choco.ps1
# Installs Chocolatey packages based on a list in the dotfiles configuration file.

# --- Script Configuration & Variables ---
$ErrorActionPreference = "Stop" # Exit on non-terminating errors

# Determine config file path
$ConfigFileName = "config.yaml"
$ConfigDir = ""
if ($env:XDG_CONFIG_HOME) {
    $ConfigDir = Join-Path -Path $env:XDG_CONFIG_HOME -ChildPath "dotfiles"
} else {
    # Fallback to default .config directory in user's home
    $UserHome = $env:USERPROFILE # Or $env:HOME on PS Core if preferred for cross-platform consistency
    $ConfigDir = Join-Path -Path $UserHome -ChildPath ".config" | Join-Path -ChildPath "dotfiles"
}
$ConfigFile = Join-Path -Path $ConfigDir -ChildPath $ConfigFileName

# --- Helper Functions ---
function Say([string]$message) {
    Write-Host "choco.ps1: $message"
}

function Say-Error([string]$message) {
    Write-Error "choco.ps1: ERROR: $message"
}

# Function to ensure the powershell-yaml module is installed
function Ensure-YamlModuleInstalled {
    Say "Checking for 'powershell-yaml' module..."
    $module = Get-Module -Name powershell-yaml -ListAvailable
    if (-not $module) {
        Say "'powershell-yaml' module not found. Attempting to install..."
        try {
            # Ensure NuGet provider is available
            if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
                Say "NuGet package provider not found. Installing..."
                Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser
                Say "NuGet package provider installed."
            } else {
                Say "NuGet package provider already available."
            }

            # Set PSGallery as trusted (if not already) to avoid prompts
            if ((Get-PSRepository -Name PSGallery).InstallationPolicy -ne 'Trusted') {
                 Say "Setting PSGallery as a trusted repository..."
                 Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
            }

            Install-Module -Name powershell-yaml -Scope CurrentUser -Force -AllowClobber -AcceptLicense
            Say "'powershell-yaml' module installed successfully."
            Import-Module powershell-yaml # Import it for the current session
        } catch {
            Say-Error "Failed to install 'powershell-yaml' module. $_"
            Say-Error "Please install it manually by running: Install-Module powershell-yaml -Scope CurrentUser"
            Say-Error "The script cannot proceed without this module."
            throw "powershell-yaml module installation failed." # Throw to stop script
        }
    } else {
        Say "'powershell-yaml' module is already installed."
        # Ensure it's imported if it was just listed as available but not loaded
        if (-not (Get-Module -Name powershell-yaml)) {
            Import-Module powershell-yaml
        }
    }
}

# --- Main Script Logic ---

Say "Starting Chocolatey package installation script."

# Ensure Chocolatey is available
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Say-Error "Chocolatey (choco) command not found. Please install Chocolatey first."
    # Consider adding choco installation here if desired, or keep it as a prerequisite from setup.ps1
    exit 1
}

# Ensure the YAML parsing module is available
Ensure-YamlModuleInstalled

# Check if config file exists
if (-not (Test-Path $ConfigFile)) {
    Say-Error "Configuration file not found at $ConfigFile"
    Say-Error "Please ensure it exists and is populated with choco packages."
    exit 1
}

Say "Reading package list from $ConfigFile"

# Read and parse the YAML file
$Config = $null
try {
    $Config = ConvertFrom-Yaml -Yaml (Get-Content -Path $ConfigFile -Raw)
} catch {
    Say-Error "Failed to parse YAML configuration file: $ConfigFile. Error: $_"
    exit 1
}

if ($null -eq $Config -or $null -eq $Config.choco -or $null -eq $Config.choco.packages) {
    Say "No Chocolatey packages found in $ConfigFile under choco.packages, or the section is empty."
    Say "Script finished."
    exit 0
}

$chocoPackages = $Config.choco.packages

if ($chocoPackages -is [string]) { # Handle case where there's only one package
    $chocoPackages = @($chocoPackages)
}

if ($chocoPackages.Count -eq 0) {
    Say "No Chocolatey packages listed to install."
    Say "Script finished."
    exit 0
}

Say "Enabling global confirmation for Chocolatey to avoid prompts during script execution."
choco feature enable -n=allowGlobalConfirmation

Say "Processing $($chocoPackages.Count) Chocolatey package(s)..."

foreach ($pkg in $chocoPackages) {
    if (-not ([string]::IsNullOrWhiteSpace($pkg))) {
        Say "Checking/installing Chocolatey package: $pkg"
        try {
            # Check if package is already installed - choco list is slow, rely on choco install idempotency
            # $installed = choco list --local-only --exact $pkg -r
            # if ($installed -match $pkg) {
            # Say "$pkg is already installed."
            # } else {
            choco install $pkg -y
            Say "Chocolatey package $pkg processed successfully."
            # }
        } catch {
            Say-Error "Failed to install or process Chocolatey package: $pkg. Error: $_"
            # Decide if you want to continue or stop. For now, it continues.
        }
    } else {
        Say "Skipping empty package name."
    }
}

Say "Disabling global confirmation for Chocolatey."
choco feature disable -n=allowGlobalConfirmation

Say "Chocolatey package installation script finished."
