#Requires -Modules Pester, powershell-yaml

# Define the path to the script to be tested relative to this test file
$ScriptPath = Resolve-Path "../../setup.ps1"

# Source the script to make its functions available.
# Using a dot source to bring functions into the current scope.
. $ScriptPath

Describe "setup.ps1 Tests" {
    Context "OS Detection" {
        Mock -CommandName Get-OSType { return "windows" } # Example, could vary per test
        It "Test-IsWindows returns true on Windows" {
            # $IsWindows is a built-in variable, set it for the test scope
            $IsWindows = $true; $IsMacOS = $false; $IsLinux = $false
            Test-IsWindows | Should -Be $true
        }
        It "Test-IsMacOS returns true on macOS" {
            $IsWindows = $false; $IsMacOS = $true; $IsLinux = $false
            Test-IsMacOS | Should -Be $true
        }
        It "Test-IsLinux returns true on Linux" {
            $IsWindows = $false; $IsMacOS = $false; $IsLinux = $true
            Test-IsLinux | Should -Be $true
        }
        It "Get-OSType returns correct OS string" {
            $IsWindows = $true; $IsMacOS = $false; $IsLinux = $false
            Get-OSType | Should -Be "windows"
            $IsWindows = $false; $IsMacOS = $true; $IsLinux = $false
            Get-OSType | Should -Be "macos"
            $IsWindows = $false; $IsMacOS = $false; $IsLinux = $true
            Get-OSType | Should -Be "linux"
        }
    }

    Context "Configuration Parsing (Get-ConfigValue)" {
        # Create a temporary dummy config file for these tests
        $TempConfigPath = Join-Path $PSScriptRoot "dummy_config.yaml"

        BeforeAll {
            $dummyYaml = @"
general:
  username: "testpsuser"
tools:
  git:
    name: "Test PS User"
    email: "testps@example.com"
feature_flags:
  withOhMyPosh: true
  installCoreSoftware: false
  interactivePrompts: false
post_install_hooks:
  enabled: true
  scripts:
    - description: "PS Test Hook"
      run_on: ["windows"]
      command: "Write-Host 'PS Test Hook Command'"
"@
            Set-Content -Path $TempConfigPath -Value $dummyYaml
            # Override the $CONFIG_FILE variable used in setup.ps1 for the test scope
            $Global:CONFIG_FILE = $TempConfigPath
        }
        AfterAll {
            Remove-Item $TempConfigPath -ErrorAction SilentlyContinue
            # Restore original CONFIG_FILE if necessary, though Pester scopes it
        }

        It "reads general.username correctly" {
            Get-ConfigValue "general.username" | Should -Be "testpsuser"
        }
        It "reads feature_flags.withOhMyPosh correctly" {
            (Get-ConfigValue "feature_flags.withOhMyPosh") | Should -Be $true
        }
         It "reads feature_flags.installCoreSoftware correctly" {
            (Get-ConfigValue "feature_flags.installCoreSoftware") | Should -Be $false
        }
        It "returns null for a non-existent key" {
            Get-ConfigValue "nonexistent.key" | Should -BeNullOrEmpty
        }
    }

    Context "Feature Flag Logic (Test-FeatureFlag)" {
        # Uses the same dummy_config.yaml from Get-ConfigValue context
        BeforeAll { # Re-establish config for this context if run independently
             $Global:CONFIG_FILE = Join-Path $PSScriptRoot "dummy_config.yaml"
        }
        It "returns true for an enabled feature (withOhMyPosh)" {
            Test-FeatureFlag -FeatureName "withOhMyPosh" | Should -Be $true
        }
        It "returns false for a disabled feature (installCoreSoftware)" {
            Test-FeatureFlag -FeatureName "installCoreSoftware" | Should -Be $false
        }
        It "returns false for a non-existent feature flag" {
            Test-FeatureFlag -FeatureName "nonExistentFlag" | Should -Be $false
        }
    }

    Context "Interactive Prompt (Confirm-UserChoice)" {
         BeforeEach { # Re-establish config for each test to ensure flag state
             $Global:CONFIG_FILE = Join-Path $PSScriptRoot "dummy_config.yaml"
        }
        It "returns DefaultChoiceForNonInteractive when interactivePrompts is false" {
            # Ensure interactivePrompts is false in dummy_config.yaml for this
            # (It is by default in the current dummy config)
            Confirm-UserChoice -Message "Test Prompt" -DefaultChoiceForNonInteractive $true | Should -Be $true
            Confirm-UserChoice -Message "Test Prompt" -DefaultChoiceForNonInteractive $false | Should -Be $false
        }

        It "prompts user and returns true for 'y' when interactive" {
            # Mock Test-FeatureFlag to simulate interactivePrompts = true
            Mock Test-FeatureFlag { if ($FeatureName -eq "interactivePrompts") { return $true } else { return $false } } -ModuleName $ScriptPath
            Mock Read-Host { return "y" } -ModuleName $ScriptPath

            Confirm-UserChoice -Message "Interactive y?" | Should -Be $true
        }
        It "prompts user and returns false for 'n' when interactive" {
            Mock Test-FeatureFlag { if ($FeatureName -eq "interactivePrompts") { return $true } else { return $false } } -ModuleName $ScriptPath
            Mock Read-Host { return "n" } -ModuleName $ScriptPath

            Confirm-UserChoice -Message "Interactive n?" | Should -Be $false
        }
         It "prompts user and returns true for empty input (default Y) when interactive" {
            Mock Test-FeatureFlag { if ($FeatureName -eq "interactivePrompts") { return $true } else { return $false } } -ModuleName $ScriptPath
            Mock Read-Host { return "" } -ModuleName $ScriptPath # Simulate Enter key

            Confirm-UserChoice -Message "Interactive Enter?" | Should -Be $true
        }
    }

    Context "EnsureFolders" {
        $testDirBase = Join-Path $PSScriptRoot "test_folders"
        BeforeEach {
            $Global:CONFIG_FILE = Join-Path $PSScriptRoot "dummy_config.yaml" # Ensure config is set
            # Mock New-Item to track calls or prevent actual creation
            Mock New-Item { Write-Output "Mocked New-Item called for $($args[0])" } -ModuleName $ScriptPath -Verifiable
            # Mock Resolve-Path for Windows to handle ~ correctly in tests
            Mock Resolve-Path { param($Path) if ($Path -like "~/*") { return (Join-Path $testDirBase ($Path -replace "~/", "")) } else { return $Path } } -ModuleName $ScriptPath
        }
        AfterEach {
            Remove-Item $testDirBase -Recurse -Force -ErrorAction SilentlyContinue
        }

        It "attempts to create defined folders if they don't exist" {
            # This test assumes Test-Path will return false for these paths initially
            # A more robust mock for Test-Path might be needed if they could exist
            Mock Test-Path { return $false } -ModuleName $ScriptPath

            EnsureFolders # Call the function

            # Check how many times New-Item was called (should be for each folder in DIRS_TO_ENSURE)
            # Number of folders defined in EnsureFolders in setup.ps1 (currently 6)
            Assert-MockCalled New-Item -Exactly 6 -Scope It -ModuleName $ScriptPath
        }
    }

    # TODO: Add tests for Install functions (e.g., Install-GitPS, Install-OhMyPoshPS, Install-PSModules)
    # These will require mocking `choco`, `Install-Module`, `Invoke-RestMethod`, etc.
    # Example:
    # Context "Install-GitPS" {
    #   BeforeEach { $Global:CONFIG_FILE = Join-Path $PSScriptRoot "dummy_config.yaml" }
    #   It "calls choco install git if Git not found on Windows" {
    #       $IsWindows = $true; $IsMacOS = $false; $IsLinux = $false
    #       Mock Get-Command { if ($_.Name -eq 'git') { return $null } elseif ($_.Name -eq 'choco') { return $true } } -ModuleName $ScriptPath
    #       Mock choco { Write-Output "choco called with: $args" } -ModuleName $ScriptPath -Verifiable
    #       Mock Confirm-UserChoice { return $true } -ModuleName $ScriptPath # Assume user confirms

    #       Install-GitPS
    #       Assert-MockCalled choco -ModuleName $ScriptPath # Check if choco was called
    #   }
    # }

    # TODO: Test Invoke-PostInstallHooksPS
    # This will require mocking Get-ConfigValue to return a hook structure, and mocking script/command execution.

    # Note: Testing the Main function directly is complex. Focus on testing individual functions.
}
