#!/usr/bin/env bash

# Update brew packages every Monday when I turn on my computer

# Define your cron job
BREW_UPDATE_CRON_JOB="@reboot /Users/josebarbosa/.kidchenko/dotfiles/cron/update.sh" >> /tmp/brew-update.log 2>&1
# BREW_UPDATE_CRON_JOB="@reboot [ "$(date +\%u)" -eq 1 ] && ~/.kidchenko/dotfiles/cron/update.sh"

# Check if job already exists
crontab -l 2>/dev/null | grep -qF "$BREW_UPDATE_CRON_JOB"
if [ $? -eq 0 ]; then
  echo "Cron job already exists. Skipping..."
else
  # Append and install new crontab
  (crontab -l 2>/dev/null; echo "$BREW_UPDATE_CRON_JOB") | crontab -
  echo "Cron job added."
fi