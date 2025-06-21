#!/usr/bin/env bats

# Make scripts in the project root and tools directory available for testing
PATH=$PATH:../../../tools:../../../ # Relative to tests/bash/bats-core/bin if run from there, or adjust

# MOCK DIRECTORY
MOCK_DIR_TOOLS_INSTALL="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)/../mocks"
PATH="$MOCK_DIR_TOOLS_INSTALL:$PATH"


setup_file() {
    # Source the script to be tested
    source ../../../tools/install.sh
}

setup() {
    # Runs before each test
    # Clear any logs or reset mocks if they write to files
    rm -f "$MOCK_DIR_TOOLS_INSTALL/brew_calls.log"
    rm -f "$MOCK_DIR_TOOLS_INSTALL/curl_calls.log"
    rm -f "$MOCK_DIR_TOOLS_INSTALL/sh_calls.log"
    rm -f "$MOCK_DIR_TOOLS_INSTALL/git_calls.log"
    # Reset mock command scripts if they are dynamically created per test, or ensure they are generic
}

teardown() {
    # Runs after each test
    # Remove mocks created specifically for a test
    rm -f "$MOCK_DIR_TOOLS_INSTALL/uname"
    rm -f "$MOCK_DIR_TOOLS_INSTALL/iscmd"
    rm -f "$MOCK_DIR_TOOLS_INSTALL/brew"
    rm -f "$MOCK_DIR_TOOLS_INSTALL/curl"
    rm -f "$MOCK_DIR_TOOLS_INSTALL/sh"
    rm -f "$MOCK_DIR_TOOLS_INSTALL/git"
    rm -f "$MOCK_DIR_TOOLS_INSTALL/clone" # if clone is a separate mock
    rm -f "$MOCK_DIR_TOOLS_INSTALL/setup_script_mock" # if setup.sh is mocked
}


# --- OS Detection Tests (specific to install.sh's own functions) ---
@test "install.sh: is_macos_install returns true when uname is Darwin" {
    echo '#!/bin/sh
    echo "Darwin"
    ' > "$MOCK_DIR_TOOLS_INSTALL/uname"
    chmod +x "$MOCK_DIR_TOOLS_INSTALL/uname"

    run is_macos_install
    [ "$status" -eq 0 ]
}

@test "install.sh: is_linux_install returns true when uname -s starts with Linux" {
    echo '#!/bin/sh
    if [ "$1" = "-s" ]; then echo "Linux"; else echo "Linux"; fi
    ' > "$MOCK_DIR_TOOLS_INSTALL/uname"
    chmod +x "$MOCK_DIR_TOOLS_INSTALL/uname"

    run is_linux_install
    [ "$status" -eq 0 ]
}

# --- install_chezmoi tests ---
@test "install_chezmoi on macOS calls brew install if chezmoi not found" {
    # Mock OS: macOS
    echo '#!/bin/sh echo "Darwin"' > "$MOCK_DIR_TOOLS_INSTALL/uname"
    chmod +x "$MOCK_DIR_TOOLS_INSTALL/uname"

    # Mock iscmd: chezmoi not found, brew found
    echo '#!/bin/sh
    if [ "$1" = "chezmoi" ]; then return 1; # not found
    elif [ "$1" = "brew" ]; then return 0; # found
    else return 1; fi
    ' > "$MOCK_DIR_TOOLS_INSTALL/iscmd"
    chmod +x "$MOCK_DIR_TOOLS_INSTALL/iscmd"

    # Mock brew
    echo '#!/bin/sh
    echo "brew call: $@" >> brew_calls.log
    if [ "$1" = "install" ] && [ "$2" = "chezmoi" ]; then exit 0; fi
    exit 1
    ' > "$MOCK_DIR_TOOLS_INSTALL/brew"
    chmod +x "$MOCK_DIR_TOOLS_INSTALL/brew"
    rm -f brew_calls.log # Clean before run

    run install_chezmoi

    [ "$status" -eq 0 ]
    run grep -q "brew call: install chezmoi" brew_calls.log
    [ "$status" -eq 0 ]
    rm -f brew_calls.log
}

@test "install_chezmoi on Linux calls curl script if chezmoi not found" {
    # Mock OS: Linux
    echo '#!/bin/sh echo "Linux"' > "$MOCK_DIR_TOOLS_INSTALL/uname"
    chmod +x "$MOCK_DIR_TOOLS_INSTALL/uname"

    # Mock iscmd: chezmoi not found, curl found
    echo '#!/bin/sh
    if [ "$1" = "chezmoi" ]; then return 1; # not found
    elif [ "$1" = "curl" ]; then return 0; # found
    else return 1; fi
    ' > "$MOCK_DIR_TOOLS_INSTALL/iscmd"
    chmod +x "$MOCK_DIR_TOOLS_INSTALL/iscmd"

    # Mock curl (to capture invocation)
    echo '#!/bin/sh
    echo "curl call: $@" >> curl_calls.log
    echo "mock_curl_output" # Simulate script output to be piped to sh
    ' > "$MOCK_DIR_TOOLS_INSTALL/curl"
    chmod +x "$MOCK_DIR_TOOLS_INSTALL/curl"
    rm -f curl_calls.log

    # Mock sh (to capture execution of script)
    echo '#!/bin/sh
    # Verify that stdin contains what curl piped
    # For simplicity, just log that sh was called with expected args
    input=$(cat)
    echo "sh call with args: $@, stdin: $input" >> sh_calls.log
    ' > "$MOCK_DIR_TOOLS_INSTALL/sh"
    chmod +x "$MOCK_DIR_TOOLS_INSTALL/sh"
    rm -f sh_calls.log

    run install_chezmoi

    [ "$status" -eq 0 ]
    run grep -q "curl call: -fsLS get.chezmoi.io" curl_calls.log
    [ "$status" -eq 0 ]
    run grep -q "sh call with args: -c mock_curl_output -- -b /usr/local/bin" sh_calls.log
    [ "$status" -eq 0 ]

    rm -f curl_calls.log sh_calls.log
}


@test "install_chezmoi does nothing if chezmoi is already installed" {
    # Mock OS: any
    echo '#!/bin/sh echo "Darwin"' > "$MOCK_DIR_TOOLS_INSTALL/uname"
    chmod +x "$MOCK_DIR_TOOLS_INSTALL/uname"

    # Mock iscmd: chezmoi found
    echo '#!/bin/sh
    if [ "$1" = "chezmoi" ]; then return 0; # found
    else return 1; fi
    ' > "$MOCK_DIR_TOOLS_INSTALL/iscmd"
    chmod +x "$MOCK_DIR_TOOLS_INSTALL/iscmd"

    # Ensure brew/curl are not called
    echo '#!/bin/sh echo "brew should not be called" >> brew_error.log; exit 1;' > "$MOCK_DIR_TOOLS_INSTALL/brew"
    chmod +x "$MOCK_DIR_TOOLS_INSTALL/brew"
    echo '#!/bin/sh echo "curl should not be called" >> curl_error.log; exit 1;' > "$MOCK_DIR_TOOLS_INSTALL/curl"
    chmod +x "$MOCK_DIR_TOOLS_INSTALL/curl"
    rm -f brew_error.log curl_error.log

    run install_chezmoi
    [ "$status" -eq 0 ]

    # Check that error logs for brew/curl were NOT created
    [ ! -f brew_error.log ]
    [ ! -f curl_error.log ]
}


# --- Main function tests (simplified) ---
@test "main in install.sh calls install_chezmoi, clone, and setup" {
    # Mock all major functions called by main
    echo '#!/bin/sh echo "install_chezmoi_called" > main_calls.log' > "$MOCK_DIR_TOOLS_INSTALL/install_chezmoi"
    chmod +x "$MOCK_DIR_TOOLS_INSTALL/install_chezmoi"

    # Mock the 'clone' function from install.sh
    # To do this properly, we'd need to source install.sh in a way that allows `clone` to be redefined
    # Or, use a more advanced mocking technique.
    # For this test, we'll assume 'clone' is an external script for simplicity of mocking PATH.
    echo '#!/bin/sh echo "clone_called" >> main_calls.log' > "$MOCK_DIR_TOOLS_INSTALL/clone" # This won't work as clone is a shell function
    chmod +x "$MOCK_DIR_TOOLS_INSTALL/clone"

    # Mock the 'setup' function from install.sh (similar challenge as 'clone')
    echo '#!/bin/sh echo "setup_called" >> main_calls.log' > "$MOCK_DIR_TOOLS_INSTALL/setup" # This won't work as setup is a shell function
    chmod +x "$MOCK_DIR_TOOLS_INSTALL/setup"

    # Mock 'git clone' directly as it's called by the real 'clone' function
    echo '#!/bin/sh echo "git_clone_called" >> main_calls.log' > "$MOCK_DIR_TOOLS_INSTALL/git"
    chmod +x "$MOCK_DIR_TOOLS_INSTALL/git"

    # Mock the sourced setup script (setup.sh)
    echo '#!/bin/sh echo "sourced_setup_sh_called" >> main_calls.log' > "$MOCK_DIR_TOOLS_INSTALL/setup.sh"
    # This mock needs to be in a place where `source ~/.kidchenko/dotfiles/setup.sh` can find it.
    # This is tricky because the path is hardcoded.
    # A better way would be for install.sh to take DOTFILES_DIR as an env var for testing.

    # For now, this test will be limited in its ability to mock clone and setup shell functions accurately
    # without more complex Bats setups (like using `stub` from bats-mock or similar).
    # We will focus on what `install_chezmoi` (as an external script in PATH) and `git clone` do.

    rm -f main_calls.log

    # Mock uname for OS detection at the start of main
    echo '#!/bin/sh echo "Darwin"' > "$MOCK_DIR_TOOLS_INSTALL/uname"
    chmod +x "$MOCK_DIR_TOOLS_INSTALL/uname"

    # Call the real main function from the sourced install.sh
    # We need to redefine clone and setup for this test to work better.
    # This is a limitation of simple PATH-based mocking for shell functions.

    # Let's redefine functions for this test scope
    # This is possible in Bats tests if functions are not read-only
    # For `tools/install.sh`, functions are not read-only.

    # Redefine clone for testing purposes
    clone() {
        say "Mocked clone function called"
        echo "mock_clone_called" >> main_calls.log
        # Simulate git clone part for this test
        git clone remote_repo_placeholder dir_placeholder || {
            say "Mock git clone failed"
            exit 1
        }
    }
    export -f clone # Make it available to the script if it's run in a subshell by `run`

    # Redefine setup for testing purposes
    setup() {
        say "Mocked setup function called"
        echo "mock_setup_called" >> main_calls.log
        # Simulate chmod + source
        # chmod -x "$MOCK_DIR_TOOLS_INSTALL/setup.sh" # Mocked setup.sh
        # source "$MOCK_DIR_TOOLS_INSTALL/setup.sh"
    }
    export -f setup

    run main # Execute the main function from tools/install.sh

    [ "$status" -eq 0 ]
    run grep -q "install_chezmoi_called" main_calls.log
    [ "$status" -eq 0 ]
    run grep -q "mock_clone_called" main_calls.log
    [ "$status" -eq 0 ]
    run grep -q "git_clone_called" main_calls.log # From our mocked git
    [ "$status" -eq 0 ]
    run grep -q "mock_setup_called" main_calls.log
    [ "$status" -eq 0 ]
    # run grep -q "sourced_setup_sh_called" main_calls.log # This part is hard due to hardcoded path in `setup`

    rm -f main_calls.log
}
