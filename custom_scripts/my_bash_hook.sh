#!/bin/bash
echo "[CUSTOM BASH HOOK] Hello from my_bash_hook.sh!"
echo "[CUSTOM BASH HOOK] Current directory: $(pwd)"
echo "[CUSTOM BASH HOOK] User: $(whoami)"
# Example: Create a file
touch ~/bash_hook_was_here.txt
echo "[CUSTOM BASH HOOK] Created ~/bash_hook_was_here.txt"
