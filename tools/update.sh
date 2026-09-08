#!/bin/bash
#
# update.sh - Check for dotfiles updates and prompt user to apply
#
# Called on shell login via .zlogin
#
# Set DOTFILES_SKIP_UPDATE_CHECK to any value to disable all of it.
#

DOTFILES_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/chezmoi"

say() { echo "[dotfiles] $1"; }

# Check prerequisites. A missing chezmoi is not the user's problem to hear
# about on every single login, so this leaves quietly rather than announcing it.
[[ -z "$DOTFILES_SKIP_UPDATE_CHECK" ]] || exit 0
command -v chezmoi &>/dev/null || exit 0
[[ -d "$DOTFILES_DIR/.git" ]] || exit 0

# Check if remote has updates.
#
# The fetch is backgrounded so login never blocks on the network, which means
# the comparison below reads the refs left by the *previous* login's fetch.
# News is therefore reported one login late; that is the price of not hanging
# a shell on an unreachable remote.
git -C "$DOTFILES_DIR" fetch --quiet 2>/dev/null &
LOCAL=$(git -C "$DOTFILES_DIR" rev-parse '@' 2>/dev/null)
REMOTE=$(git -C "$DOTFILES_DIR" rev-parse '@{u}' 2>/dev/null)

if [[ -z "$REMOTE" || "$LOCAL" == "$REMOTE" ]]; then
    say "Already up to date."
    exit 0
fi

# Behind, ahead, or diverged - only the first is ours to fix. `chezmoi update`
# pulls, so offering it on top of unpushed local work is wrong.
COUNTS=$(git -C "$DOTFILES_DIR" rev-list --left-right --count '@...@{u}' 2>/dev/null)
AHEAD=$(awk '{print $1+0}' <<<"$COUNTS")
BEHIND=$(awk '{print $2+0}' <<<"$COUNTS")
AHEAD=${AHEAD:-0}; BEHIND=${BEHIND:-0}

if (( AHEAD > 0 )); then
    say "Local dotfiles have diverged from the remote ($AHEAD ahead, $BEHIND behind)."
    exit 0
fi

# Answering needs a keyboard. Without one there is nobody to ask, and a stray
# line on a script's stdout is worse than silence.
[[ -t 0 ]] || exit 0

# The announcement is the question. Printing the news on its own line first and
# then asking reads as two events for one piece of information.
if (( BEHIND == 1 )); then NOUN="commit"; else NOUN="commits"; fi
read -p "[dotfiles] New version available ($BEHIND $NOUN behind). Update now? [y/n]: " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    if chezmoi update; then
        say "Updated successfully!"
    else
        say "Update failed. Run 'dotfiles update' to retry."
    fi
else
    say "Update skipped."
fi
