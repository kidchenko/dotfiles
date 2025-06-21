#Requires -Modules Pester

# Define the path to the script to be tested
$ScriptPath = Resolve-Path "../../tools/install.ps1"

# Source the script. Using a dot source.
. $ScriptPath

Describe "install.ps1 Tests" {

    Context "OS Detection (Install Script)" {
        It "Test-IsWindows-Install returns true on Windows" {
            $IsWindows = $true; $IsMacOS = $false; $IsLinux = $false
            Test-IsWindows-Install | Should -Be $true
        }
        It "Get-OSType-Install returns 'windows' on Windows" {
            $IsWindows = $true; $IsMacOS = $false; $IsLinux = $false
            Get-OSType-Install | Should -Be "windows"
        }
        # Add similar tests for macOS and Linux if those $IsMacOS/$IsLinux vars are expected to be set in this script's context
    }

    Context "IsCommand" {
        BeforeEach {
            # Default to Windows for these tests unless overridden
            $IsWindows = $true; $IsMacOS = $false; $IsLinux = $false
        }

        It "IsCommand uses where.exe on Windows and finds command" {
            Mock where.exe { return "/path/to/mockedcmd.exe" } # Simulate command found
            IsCommand "mockedcmd" | Should -Not -BeNullOrEmpty
            Assert-MockCalled where.exe -Exactly 1
        }

        It "IsCommand uses where.exe on Windows and does not find command" {
            Mock where.exe { throw "Command not found" } # Simulate command not found
            IsCommand "nonexistentcmd" | Should -BeNullOrEmpty
            Assert-MockCalled where.exe -Exactly 1
        }

        It "IsCommand uses Get-Command on non-Windows and finds command" {
            $IsWindows = $false; $IsMacOS = $true # Simulate macOS
            Mock Get-Command { return [pscustomobject]@{ Name = "mockedcmd" } } # Simulate command found
            IsCommand "mockedcmd" | Should -Not -BeNullOrEmpty
            Assert-MockCalled Get-Command -Exactly 1 -Scope It -ParameterFilter { $Name -eq "mockedcmd" }
        }

        It "IsCommand uses Get-Command on non-Windows and does not find command" {
            $IsWindows = $false; $IsLinux = $true # Simulate Linux
            Mock Get-Command { return $null } # Simulate command not found
            IsCommand "nonexistentcmd" | Should -BeNullOrEmpty
            Assert-MockCalled Get-Command -Exactly 1 -Scope It -ParameterFilter { $Name -eq "nonexistentcmd" }
        }
    }

    Context "Install-Chezmoi (Windows)" {
        BeforeEach {
            $IsWindows = $true; $IsMacOS = $false; $IsLinux = $false
            # Ensure IsCommand is available or mocked if Install-Chezmoi calls it internally
            Mock IsCommand { param($cmd) if($cmd -eq "chezmoi") { return $false } else { return $true} } # Mock: chezmoi not found
            Mock choco { Write-Output "choco called with $args" } -Verifiable
        }

        It "calls choco install chezmoi if not already installed" {
            Install-Chezmoi
            Assert-MockCalled choco -Exactly 1 -Scope It -ParameterFilter { $ArgumentList -contains "install" -and $ArgumentList -contains "chezmoi" }
        }

        It "does not call choco if chezmoi is already installed" {
            Mock IsCommand { param($cmd) if($cmd -eq "chezmoi") { return $true } } # Mock: chezmoi IS found
            Install-Chezmoi
            Assert-MockCalled choco -Exactly 0 -Scope It
        }
    }

    # Context "CheckDeps" - Would require mocking IsCommand, Read-Host
    # Context "InstallDeps" - Would require mocking Install-Choco, Install-DotFileDependency
    # Context "Install-Choco" - Complex due to external script execution

    Context "Clone" {
        $TestDotfilesDir = "tests/temp_dotfiles_dir"
        BeforeEach {
            # Override DOTFILES_DIR for testing
            $Global:DOTFILES_DIR = $TestDotfilesDir
            New-Item -Path $TestDotfilesDir -ItemType Directory -Force | Out-Null
            Mock git { Write-Output "git called with $args" } -Verifiable
        }
        AfterEach {
            Remove-Item $TestDotfilesDir -Recurse -Force -ErrorAction SilentlyContinue
        }

        It "removes existing DOTFILES_DIR and calls git clone" {
            # Create a dummy file to ensure removal is tested
            New-Item -Path (Join-Path $TestDotfilesDir "dummy.txt") -ItemType File | Out-Null

            Clone

            (Test-Path (Join-Path $TestDotfilesDir "dummy.txt")) | Should -Be $false # Directory should be cleared
            Assert-MockCalled git -Exactly 1 -Scope It -ParameterFilter { $ArgumentList -contains "clone" }
        }
    }

    # Note: Testing Main function directly is complex. Focus on units.
    # To test Main, you'd mock:
    # CheckDeps, InstallDeps, Install-DotFilesPsGetModules, Install-Chezmoi, Clone, Invoke-Setup
}
