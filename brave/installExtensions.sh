#!/bin/bash

# Script to open installation pages for Brave/Chrome extensions

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXTENSIONS_FILE="$SCRIPT_DIR/extensions.txt"

# Check if extensions.txt file exists
if [ ! -f "$EXTENSIONS_FILE" ]; then
  echo "Error: Extensions file not found at $EXTENSIONS_FILE"
  exit 1
fi

echo "Processing extensions from $EXTENSIONS_FILE..."

# Read the extensions file line by line
while IFS= read -r line || [[ -n "$line" ]]; do
  # Trim leading/trailing whitespace
  trimmed_line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

  # Skip empty lines and lines starting with #
  if [ -z "$trimmed_line" ] || [[ "$trimmed_line" == \#* ]]; then
    continue
  fi

  # Extract extension ID (part before any # comment)
  extension_id=$(echo "$trimmed_line" | awk -F'#' '{print $1}' | sed 's/[[:space:]]*$//')

  # Skip if no valid ID is found after stripping comment
  if [ -z "$extension_id" ]; then
    continue
  fi

  echo "Found extension ID: $extension_id"
  install_url="https://chrome.google.com/webstore/detail/$extension_id"

  echo "Opening install page for $extension_id..."

  # Check OS and open the URL
  if [[ "$(uname)" == "Darwin" ]]; then # macOS
    if command -v open &> /dev/null && open -Ra "Brave Browser"; then
      open -a "Brave Browser" "$install_url"
    else
      echo "Warning: 'Brave Browser' application not found or 'open' command failed. Attempting default browser."
      open "$install_url" # Fallback to default browser
    fi
  elif [[ "$(uname)" == "Linux" ]]; then # Linux
    # Try to use brave-browser directly if available, as xdg-open might open in a different default browser.
    if command -v brave-browser &> /dev/null; then
      brave-browser "$install_url" &
    elif command -v xdg-open &> /dev/null; then # Fallback to xdg-open
      xdg-open "$install_url" &
    else
      echo "Error: Could not find 'brave-browser' or 'xdg-open' to open the URL on Linux."
      echo "Please install one of these or open the URL manually: $install_url"
    fi
  else
    echo "Warning: Unsupported OS: $(uname). Please open the URL manually: $install_url"
  fi

  # Optional: Add a small delay to prevent overwhelming the system or browser
  # sleep 1
done < "$EXTENSIONS_FILE"

echo "Finished processing extensions."

# Make the script executable (this line will be run when the file is created by the agent,
# but it's good practice to include it if the script were manually created)
# chmod +x "$SCRIPT_DIR/installExtensions.sh"
