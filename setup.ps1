$ErrorActionPreference = "Stop"

$REPO="kidchenko/dotfiles"
$DOTFILES_DIR="~/.$REPO"
$CONFIG_FILE = "$DOTFILES_DIR/config.yaml"

# Logging functions
function Log-Message {
    param (
        [string]$Level,
        [string]$Message,
        [string]$Color
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $Color
}

function Log-Info {
    param ([string]$Message)
    Log-Message "INFO" $Message "Green"
}

function Log-Warn {
    param ([string]$Message)
    Log-Message "WARN" $Message "Yellow"
}

function Log-Error {
    param ([string]$Message)
    Log-Message "ERROR" $Message "Red"
}

# OS detection functions
function Get-OSType {
    if ($IsWindows) { return "windows" }
    elseif ($IsMacOS) { return "macos" }
    elseif ($IsLinux) { return "linux" }
    else { return "unknown" }
}

function Test-IsMacOS { return $IsMacOS }
function Test-IsLinux { return $IsLinux }
function Test-IsWindows { return $IsWindows }
# End OS detection functions

# Function to read values from YAML file
function Get-ConfigValue {
    param (
        [string]$Path
    )
    try {
        $config = ConvertFrom-YAML (Get-Content $CONFIG_FILE -Raw -ErrorAction Stop)
        $value = $config
        foreach ($key in $Path.Split('.')) {
            if ($value -is [hashtable] -and $value.ContainsKey($key)) {
                $value = $value[$key]
            } elseif ($value -is [System.Management.Automation.PSCustomObject] -and $value.PSObject.Properties[$key]) {
                $value = $value.PSObject.Properties[$key].Value
            } else {
                # Key not found or path is invalid
                return $null
            }
        }
        return $value
    } catch {
        Log-Error "Error reading or parsing YAML config: $($_.Exception.Message) for path $Path"
        return $null
    }
}

# Function to check if a feature flag is enabled
function Test-FeatureFlag {
    param (
        [string]$FeatureName
    )
    $value = Get-ConfigValue "feature_flags.$FeatureName"
    # YAML true is $true in PowerShell, false is $false, null if not found
    return [System.Convert]::ToBoolean($value)
}

# Interactive Prompt Function
function Confirm-UserChoice {
    param(
        [string]$Message,
        [bool]$DefaultChoiceForNonInteractive = $true # Default to Yes for non-interactive scenarios
    )

    if (-not (Test-FeatureFlag -FeatureName "interactivePrompts")) {
        Log-Info "Interactive prompts disabled. Defaulting to '$($DefaultChoiceForNonInteractive)' for prompt: ""$Message"""
        return $DefaultChoiceForNonInteractive
    }

    while ($true) {
        $response = Read-Host -Prompt "$Message [Y/n]"
        if ($response -eq "" ) { # User pressed Enter, default to Yes
            return $true
        }
        if ($response -match '^[Yy]$') {
            return $true
        } elseif ($response -match '^[Nn]$') {
            return $false
        } else {
            Log-Warn "Invalid input. Please enter 'y' for yes or 'n' for no."
        }
    }
}


# Installation Functions
function Install-GitPS {
    # Git is fundamental, usually non-interactive, but shown for pattern
    if (Test-IsWindows) {
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            if (Confirm-UserChoice -Message "Git is not installed. Install Git?" -DefaultChoiceForNonInteractive $true) {
                Log-Info "Attempting to install Git using Chocolatey..."
                if (Get-Command choco -ErrorAction SilentlyContinue) {
                    choco install git -y --params "/GitAndUnixToolsOnPath /NoAutoCrlf"
                    Log-Info "Git installed via Chocolatey. Please restart your terminal for changes to take effect."
                } else {
                    Log-Error "Chocolatey not found. Cannot install Git. Please install Chocolatey or Git manually."
                }
            } else {
                Log-Info "Skipping Git installation based on user input."
            }
        } else {
            Log-Info "Git is already installed."
        }
    } elseif (Test-IsMacOS) {
        Log-Info "On macOS, Git installation is typically handled by Homebrew (via setup.sh or manually)."
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
             Log-Warn "Git not found on macOS. Consider running setup.sh or installing via Homebrew."
        } else {
            Log-Info "Git is already installed on macOS."
        }
    } elseif (Test-IsLinux) {
         Log-Info "On Linux, Git installation is typically handled by the system package manager (via setup.sh or manually)."
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
             Log-Warn "Git not found on Linux. Consider running setup.sh or installing via your package manager."
        } else {
            Log-Info "Git is already installed on Linux."
        }
    }
}

function Install-BravePS {
    if (Test-IsWindows) {
        $braveInstalled = choco list --local-only --exact brave -r
        if (-not $braveInstalled) {
            if (Confirm-UserChoice -Message "Brave Browser is not installed. Install Brave Browser?" -DefaultChoiceForNonInteractive $true) {
                Log-Info "Attempting to install Brave Browser using Chocolatey..."
                if (Get-Command choco -ErrorAction SilentlyContinue) {
                    choco install brave -y || Log-Error "Failed to install Brave Browser with Chocolatey."
                } else {
                    Log-Error "Chocolatey not found. Cannot install Brave Browser. Please install Chocolatey or Brave manually."
                }
            } else {
                Log-Info "Skipping Brave Browser installation based on user input."
            }
        } else {
            Log-Info "Brave Browser is already installed (found via choco list)."
        }
    } elseif (Test-IsMacOS) {
        Log-Info "On macOS, Brave Browser installation is typically handled by Homebrew (via setup.sh or manually)."
        # Could add 'brew list brave-browser' check if brew is available in PS on macOS
    } elseif (Test-IsLinux) {
        Log-Info "On Linux, Brave Browser installation is typically handled by the system package manager (via setup.sh or manually)."
    }
}

function Install-OhMyPoshPS {
    if (Test-IsWindows) {
        if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
            if (Confirm-UserChoice -Message "Oh My Posh is not installed. Install Oh My Posh for PowerShell?" -DefaultChoiceForNonInteractive $true) {
                Log-Info "Attempting to install Oh My Posh for PowerShell..."
                if (Get-Command choco -ErrorAction SilentlyContinue) {
                    Log-Info "Installing Oh My Posh via Chocolatey for PowerShell..."
                    choco install oh-my-posh -y || Log-Error "Failed to install Oh My Posh with Chocolatey."
                } elseif (Get-Command winget -ErrorAction SilentlyContinue) {
                    Log-Info "Installing Oh My Posh via winget..."
                    try {
                        winget install JanDeDobbeleer.OhMyPosh -s winget --accept-source-agreements --accept-package-agreements || Log-Error "Winget install failed."
                    } catch {
                        Log-Error "Winget command failed to run: $($_.Exception.Message)"
                    }
                } else {
                    Log-Warn "Chocolatey and Winget not found. Attempting Oh My Posh script install for PowerShell..."
                    try {
                        Invoke-Expression (Invoke-RestMethod -Uri 'https://ohmyposh.dev/install.ps1')
                        Log-Info "Oh My Posh installed via script. You might need to run `oh-my-posh init pwsh --config 'path/to/your/theme.omp.json'` and add it to your $PROFILE."
                    } catch {
                        Log-Error "Failed to install Oh My Posh using script: $($_.Exception.Message)"
                    }
                }
            } else {
                Log-Info "Skipping Oh My Posh for PowerShell installation based on user input."
            }
        } else {
            Log-Info "Oh My Posh is already installed."
        }
    } else {
        Log-Info "Oh My Posh installation for Bash/Zsh is handled by setup.sh on macOS/Linux."
    }
}

function Install-PSModules {
    if (Test-IsWindows) {
        Log-Info "Checking required PowerShell modules..."
        $modules = @{
            "posh-git" = "Install posh-git for Git integration in PowerShell."
            "PowerShellGet" = "Ensure latest PowerShellGet." # Often pre-installed
            "PSReadLine" = "Ensure latest PSReadLine for better command line editing." # Often pre-installed
            "Terminal-Icons" = "Install Terminal-Icons for better `ls` output."
            "PSZLocation" = "Install PSZLocation for z-like directory navigation." # 'z' equivalent
        }

        # Ensure NuGet provider is available for Install-Module
        if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
            Log-Info "NuGet provider not found. Installing..."
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser || (Log-Error "Failed to install NuGet provider."; return)
        }

        foreach ($moduleName in $modules.Keys) {
            if (-not (Get-Module -ListAvailable -Name $moduleName)) {
                Log-Info "Attempting to install PowerShell module: $moduleName. Reason: $($modules[$moduleName])"
                try {
                    Install-Module $moduleName -Scope CurrentUser -Force -AllowClobber -SkipPublisherCheck -ErrorAction Stop
                    Log-Info "$moduleName installed successfully."
                } catch {
                    Log-Error "Failed to install module $moduleName: $($_.Exception.Message)"
                }
            } else {
                Log-Info "PowerShell module $moduleName is already available."
            }
        }
    } else {
        Log-Info "PowerShell module installation is specific to Windows environment here."
    }
}
# End Installation Functions

# Post-install hooks execution
function Invoke-PostInstallHooksPS {
    Log-Info "Checking for post-install hooks..."
    if (-not (Test-FeatureFlag -FeatureName "post_install_hooks.enabled")) {
        Log-Info "Post-install hooks are disabled globally. Skipping."
        return
    }

    $hooks = Get-ConfigValue "post_install_hooks.scripts"
    if (-not $hooks -or $hooks.Count -eq 0) {
        Log-Info "No post-install hooks defined in config.yaml."
        return
    }

    Log-Info "Found $($hooks.Count) post-install hook(s) defined. Processing..."
    $currentOS = Get-OSType
    $dotfilesDirExpanded = Resolve-Path $DOTFILES_DIR # Ensure ~ is expanded

    foreach ($hook in $hooks) {
        $runOn = $hook.run_on
        $hookScript = $hook.script
        $hookCommand = $hook.command
        $hookDescription = $hook.description

        if ($runOn -contains $currentOS) {
            Log-Info "Running post-install hook: $hookDescription"
            if (-not [string]::IsNullOrWhiteSpace($hookScript)) {
                $scriptPath = Join-Path -Path $dotfilesDirExpanded -ChildPath $hookScript
                if (Test-Path $scriptPath) {
                    Log-Info "Executing script: $scriptPath"
                    try {
                        # Invoke the script. If it's .ps1, it will be executed by PowerShell.
                        # If it's .sh on WSL, it might need `wsl.exe bash script.sh`
                        # For simplicity, assuming .ps1 or directly executable commands.
                        Invoke-Expression "& `"$scriptPath`"" -ErrorAction Stop
                        Log-Info "Script $scriptPath executed successfully."
                    } catch {
                        Log-Error "Script $scriptPath failed: $($_.Exception.Message)"
                    }
                } else {
                    Log-Error "Script $scriptPath not found."
                }
            } elseif (-not [string]::IsNullOrWhiteSpace($hookCommand)) {
                Log-Info "Executing command: $hookCommand"
                try {
                    Invoke-Expression $hookCommand -ErrorAction Stop
                    Log-Info "Command executed successfully: $hookCommand"
                } catch {
                    Log-Error "Command failed: $($_.Exception.Message) for command: $hookCommand"
                }
            } else {
                Log-Warn "Hook for $currentOS has no valid script or command: $hookDescription"
            }
        } else {
            Log-Info "Skipping hook: '$hookDescription' as it's not targeted for OS '$currentOS' (run_on: $($runOn -join ', '))."
        }
        Log-Info "" # Add a newline for better log readability
    }
    Log-Info "Finished processing post-install hooks."
}


function EnsureFolders {
    $username = Get-ConfigValue "general.username"
    Log-Info "Using username from config: $username for folder checks (if applicable in future)"

    $dirsToEnsure = @(
        "~/lambda3",
        "~/jetabroad",
        "~/thoughtworks",
        "~/sevenpeaks",
        "~/isho",
        "~/kidchenko"
    )

    foreach ($dirPathStr in $dirsToEnsure) {
        $dirPath = Resolve-Path $dirPathStr # Expands ~
        if (!(Test-Path $dirPath)) {
            Log-Info "Directory $dirPath does not exist. Creating..."
            try {
                New-Item -ItemType Directory -Path $dirPath -ErrorAction Stop | Out-Null
                Log-Info "Directory $dirPath created successfully."
            } catch {
                Log-Error "Failed to create directory $dirPath: $($_.Exception.Message)"
            }
        } else {
            Log-Info "Directory $dirPath already exists. Skipping creation."
        }
    }
}

function ReloadProfile {
	Log-Info "Reload $PROFILE"
	. $PROFILE
}

function Main () {
	Log-Info "Running on OS: $(Get-OSType)"
	Install-PowershellYaml # For reading config.yaml

    # Core software installations (Windows focused for this script part)
    if (Test-FeatureFlag -FeatureName "installCoreSoftware") {
        Log-Info "Feature 'installCoreSoftware' is enabled. Proceeding with core software installations for Windows."
        if (Test-IsWindows) {
            Install-GitPS
            Install-BravePS
        } else {
            Log-Info "Skipping Windows-specific core software (Git, Brave via choco) as not on Windows."
        }
    } else {
        Log-Info "Feature 'installCoreSoftware' is disabled. Skipping core software installations."
    }

    # PowerShell Modules
    if (Test-FeatureFlag -FeatureName "installPowerShellModules") {
        if (Test-IsWindows) {
            Install-PSModules
        } else {
            Log-Info "Skipping PowerShell module installation as not on Windows."
        }
    } else {
        Log-Info "Feature 'installPowerShellModules' is disabled. Skipping PowerShell module installation."
    }

    Log-Info "Starting chezmoi operations..."
    $chezmoiExists = Get-Command chezmoi -ErrorAction SilentlyContinue
    if (-not $chezmoiExists) {
        Log-Error "chezmoi command not found. Please ensure it's installed and in PATH."
        # Consider exiting or stopping further execution if chezmoi is critical
        return
    }

    # Check if chezmoi is initialized by trying a read-only command
    try {
        chezmoi state data > $null
        Log-Info "chezmoi already initialized."
    } catch {
        Log-Info "Initializing chezmoi..."
        chezmoi init # Add error handling if needed
    }

	Log-Info "Adding dotfiles to chezmoi source state..."
    # These are idempotent, chezmoi handles existing files gracefully
	chezmoi add ~/profile.ps1
	chezmoi add ~/.login.ps1
	chezmoi add ~/.modules.ps1
	chezmoi add ~/.aliases.ps1
    # .gitconfig is handled by setup.sh, but if running standalone, it would be added here.
    # For consistency, we can add it here too. Chezmoi handles duplicates.
    chezmoi add ~/.gitconfig
	chezmoi add ~/.hyper.win.js

    Log-Info "Configuring git global settings..."
    $gitName = Get-ConfigValue "tools.git.name"
    $gitEmail = Get-ConfigValue "tools.git.email"

    $currentGitName = git config --global user.name 2>$null
    $currentGitEmail = git config --global user.email 2>$null

    if ($currentGitName -ne $gitName) {
        Log-Info "Setting git global user.name to '$gitName'..."
        git config --global user.name "$gitName" # Add error handling if needed
    } else {
        Log-Info "git global user.name is already set to '$gitName'."
    }

    if ($currentGitEmail -ne $gitEmail) {
        Log-Info "Setting git global user.email to '$gitEmail'..."
        git config --global user.email "$gitEmail" # Add error handling if needed
    } else {
        Log-Info "git global user.email is already set to '$gitEmail'."
    }

    # Re-add .gitconfig to chezmoi if it was changed by the above commands
    Log-Info "Ensuring .gitconfig in chezmoi source state is up-to-date..."
    chezmoi add ~/.gitconfig

	Log-Info "Applying dotfiles with chezmoi..."
	chezmoi apply # Add error handling if needed
    EnsureFolders

    # Feature flag controlled sections
    if (Test-FeatureFlag -FeatureName "withOhMyPosh") {
        Install-OhMyPoshPS
    } else {
        Log-Info "Skipping Oh My Posh installation (feature flag 'withOhMyPosh' is false)."
    }

    if (Test-FeatureFlag -FeatureName "installDevelopmentTools") {
        Log-Info "Attempting to install development tools (feature flag 'installDevelopmentTools' is true)..."
        # Placeholder for other development tools installation logic for PowerShell/Windows
        # e.g. Install-VSCode, Install-DockerDesktop etc.
        Log-Info "Further development tools installation logic for PowerShell/Windows would run here."
    } else {
        Log-Info "Skipping development tools installation (feature flag 'installDevelopmentTools' is false)."
    }

    if (Test-FeatureFlag -FeatureName "setupGitAliases") {
        Log-Info "Attempting to setup Git aliases (feature flag 'setupGitAliases' is true)..."
        # Placeholder for Git aliases setup logic
        Log-Info "Git aliases setup logic would run here."
    } else {
        Log-Info "Skipping Git aliases setup (feature flag 'setupGitAliases' is false)."
    }

    # Run post-install hooks before reloading profile
    Invoke-PostInstallHooksPS

	ReloadProfile
}

function Install-PowershellYaml {
    if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
        Log-Warn "powershell-yaml module not found, attempting to install..."
        try {
            Install-Module powershell-yaml -Scope CurrentUser -Force -ErrorAction Stop
            Log-Info "powershell-yaml module installed successfully."
        } catch {
            Log-Error "Failed to install powershell-yaml module: $($_.Exception.Message)"
        }
    } else {
        Log-Info "powershell-yaml module is already installed."
    }
}

Main
