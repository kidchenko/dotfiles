#!/usr/bin/env bats

# Load helper library for Bats (optional, but good for extensions)
# load 'bats-support/load'
# load 'bats-assert/load'

# Make scripts in the project root and tools directory available for testing
# Adjust path as necessary if tests are run from a different CWD
PATH=$PATH:../../tools:../../

# MOCK DIRECTORY - this should be first in PATH for tests
MOCK_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)/../mocks"
PATH="$MOCK_DIR:$PATH"

# Dummy config file for tests
TEST_CONFIG_FILE="tests/bash/dummy_config.yaml"

setup_file() {
    # Create a dummy config.yaml for tests
    cat > "$TEST_CONFIG_FILE" <<EOF
general:
  username: "testuser"
tools:
  git:
    name: "Test User"
    email: "test@example.com"
feature_flags:
  withOhMyPosh: true
  installCoreSoftware: true
  installDevelopmentTools: false
  installPowerShellModules: false # Not relevant for bash tests
  setupGitAliases: true
  interactivePrompts: false # Default to non-interactive for most tests
post_install_hooks:
  enabled: true
  scripts:
    - run_on: [macos, linux]
      script: "custom_scripts/my_bash_hook.sh"
      description: "Test Bash Hook"
    - run_on: [macos]
      command: "echo 'Test macOS command hook'"
      description: "Test macOS command"
EOF

    # Source the script to be tested (or parts of it)
    # This makes its functions available to the test cases.
    # Be careful with sourcing scripts that have direct execution blocks outside functions.
    # setup.sh is designed to be sourced by tools/install.sh, but its main() is called at the end.
    # For testing functions, we can source it and not call main().
    # Or, we can extract functions to a library if setup.sh becomes too complex.
    source ../../setup.sh
}

teardown_file() {
    rm -f "$TEST_CONFIG_FILE"
}

setup() {
    # Runs before each test.
    # Ensure CONFIG_FILE in setup.sh points to our dummy config
    export CONFIG_FILE="$TEST_CONFIG_FILE"
    # Reset any global state if necessary
}

# --- OS Detection Tests ---
@test "is_macos returns true when uname is Darwin" {
    # Mock uname
    echo '#!/bin/sh
    echo "Darwin"
    ' > "$MOCK_DIR/uname"
    chmod +x "$MOCK_DIR/uname"

    run is_macos
    [ "$status" -eq 0 ] # 0 is true in Bash exit codes

    # Clean up mock
    rm -f "$MOCK_DIR/uname"
}

@test "is_linux returns true when uname -s starts with Linux" {
    echo '#!/bin/sh
    if [ "$1" = "-s" ]; then
        echo "Linux"
    else
        echo "Linux" # Default for uname with no args
    fi
    ' > "$MOCK_DIR/uname"
    chmod +x "$MOCK_DIR/uname"

    run is_linux
    [ "$status" -eq 0 ]

    rm -f "$MOCK_DIR/uname"
}

# --- Config Parsing Tests ---
@test "get_config_value reads from dummy_config.yaml" {
    # Mock yq
    echo '#!/bin/sh
    # Basic mock: if $1 is ".general.username" and $2 is test config, echo testuser
    if [ "$1" = ".general.username" ] && [ "$2" = "tests/bash/dummy_config.yaml" ]; then
        echo "testuser"
    elif [ "$1" = ".feature_flags.withOhMyPosh" ] && [ "$2" = "tests/bash/dummy_config.yaml" ]; then
        echo "true"
    fi
    # Add more conditions as needed for other tests
    ' > "$MOCK_DIR/yq"
    chmod +x "$MOCK_DIR/yq"

    result="$(get_config_value ".general.username")"
    [ "$result" = "testuser" ]

    result_flag="$(get_config_value ".feature_flags.withOhMyPosh")"
    [ "$result_flag" = "true" ]

    rm -f "$MOCK_DIR/yq"
}

# --- Feature Flag Tests ---
@test "is_feature_enabled returns true for withOhMyPosh" {
    # Mock yq for this specific test if not covered by global mock
    echo '#!/bin/sh
    echo "true"
    ' > "$MOCK_DIR/yq"
    chmod +x "$MOCK_DIR/yq"

    run is_feature_enabled "withOhMyPosh"
    [ "$status" -eq 0 ]

    rm -f "$MOCK_DIR/yq"
}

@test "is_feature_enabled returns false for installDevelopmentTools" {
    echo '#!/bin/sh
    echo "false" # As per dummy_config.yaml
    ' > "$MOCK_DIR/yq"
    chmod +x "$MOCK_DIR/yq"

    run is_feature_enabled "installDevelopmentTools"
    [ "$status" -eq 1 ] # 1 is false

    rm -f "$MOCK_DIR/yq"
}

# --- ensureFolders tests ---
@test "ensureFolders attempts to create configured directories" {
    # Mock mkdir and get_config_value (or rely on the yq mock)
    echo '#!/bin/sh
    echo "testuser" # For .general.username
    ' > "$MOCK_DIR/yq" # Mock yq to control username
    chmod +x "$MOCK_DIR/yq"

    # Mock mkdir to record calls
    echo '#!/bin/sh
    echo "mkdir called with: $@" >> mkdir_calls.log
    ' > "$MOCK_DIR/mkdir"
    chmod +x "$MOCK_DIR/mkdir"

    # Ensure log file is clean
    rm -f mkdir_calls.log

    ensureFolders # Call the function

    # Check if mkdir was called for each directory (adjust for actual paths)
    # This is a simple check; more robust would be to check specific paths
    run grep -q "/lambda3" mkdir_calls.log && \
        grep -q "/jetabroad" mkdir_calls.log && \
        grep -q "/thoughtworks" mkdir_calls.log && \
        grep -q "/sevenpeaks" mkdir_calls.log && \
        grep -q "/isho" mkdir_calls.log && \
        grep -q "/kidchenko" mkdir_calls.log
    [ "$status" -eq 0 ]

    rm -f "$MOCK_DIR/yq" "$MOCK_DIR/mkdir" mkdir_calls.log
}


# --- Interactive Prompt Tests ---
@test "ask_user_confirm defaults to yes when interactivePrompts is false" {
    # Override config for this test
    export CONFIG_FILE="$TEST_CONFIG_FILE"
    # Ensure interactivePrompts is false (as per dummy_config.yaml via yq mock)
    echo '#!/bin/sh
    if [ "$1" = ".feature_flags.interactivePrompts" ]; then echo "false"; else echo "true"; fi
    ' > "$MOCK_DIR/yq"
    chmod +x "$MOCK_DIR/yq"

    run ask_user_confirm "Test prompt"
    [ "$status" -eq 0 ] # Should be 'yes' (0)

    rm -f "$MOCK_DIR/yq"
}

@test "ask_user_confirm reads 'y' correctly when interactive" {
    export CONFIG_FILE="$TEST_CONFIG_FILE"
    echo '#!/bin/sh
    if [ "$1" = ".feature_flags.interactivePrompts" ]; then echo "true"; else echo "some_value"; fi
    ' > "$MOCK_DIR/yq"
    chmod +x "$MOCK_DIR/yq"

    # Mock 'read' by providing input
    # This is tricky with Bats. A common way is to pipe input.
    # If 'read' is directly in the function, this can be hard.
    # For this example, we'll assume 'read' can be fed via pipe for simplicity.
    # A more robust solution might involve a mock 'read' script.

    # This test is more conceptual for Bats as direct `read` mocking is complex.
    # Actual test might involve calling a wrapper script that calls the function.
    # For now, we'll test the non-interactive path more reliably.
    skip "Interactive 'read' mocking is complex in Bats, focusing on non-interactive."

    # Conceptual:
    # run bash -c "source ../../setup.sh; printf 'y\n' | ask_user_confirm 'Interactive Test'"
    # [ "$status" -eq 0 ]

    rm -f "$MOCK_DIR/yq"
}

# TODO: Add more tests for other functions and main logic flow
# - Test install_yq (mocking brew, apt-get)
# - Test install_git_bash (mocking git, brew, apt-get, and ask_user_confirm)
# - Test run_post_install_hooks_bash (mocking yq for hook parsing, and the hook scripts/commands)
# - Test main() by checking if mocks for major functions are called in order / with flags.
#   This often involves setting up specific mocks for each function call expected.

# Example for testing if a mocked function was called:
# @test "main calls install_yq" {
#   echo '#!/bin/sh echo "install_yq_called" > install_yq.log' > "$MOCK_DIR/install_yq"
#   chmod +x "$MOCK_DIR/install_yq"
#   rm -f install_yq.log
#
#   run main # This will run the actual main function, be careful
#
#   run grep -q "install_yq_called" install_yq.log
#   [ "$status" -eq 0 ]
#   rm -f "$MOCK_DIR/install_yq" install_yq.log
# }
# Note: Testing main() directly can be very complex due to its scope.
# It's often better to test functions it calls.
# If main() must be tested, ensure all its dependencies are thoroughly mocked.

# Example of a mock for a command like 'git'
# setup() {
#   export GIT_CONFIG_CALLS="" # Reset for each test
#   echo '#!/bin/bash
#   if [ "$1" = "config" ]; then
#     echo "git config called with: $@" >> "$BATS_TEST_DIRNAME/git_config_calls.log"
#     export GIT_CONFIG_CALLS="$GIT_CONFIG_CALLS$@;"
#   fi
#   # Add other git command mocks as needed
#   ' > "$MOCK_DIR/git"
#   chmod +x "$MOCK_DIR/git"
# }
# teardown() {
#  rm -f "$MOCK_DIR/git"
#  rm -f "$BATS_TEST_DIRNAME/git_config_calls.log"
# }

# @test "Git config is set in main" {
#   # Mock get_config_value to return specific git name/email
#   # ...
#   # Run the part of main() that sets git config, or a refactored function
#   # ...
#   # Assert that GIT_CONFIG_CALLS contains expected parameters or log file has entries
# }
