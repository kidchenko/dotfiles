#!/bin/sh

REPO=${REPO:-kidchenko/dotfiles}
DOTFILES_DIR=${DOTFILES_DIR:-~/.${REPO}}

if [[ -f "$DOTFILES_DIR/tools/update.sh" ]]; then
    {
        chmod a+x "$DOTFILES_DIR/tools/update.sh"
        "$DOTFILES_DIR/tools/update.sh" &&

    } || {
        echo "fail to update..."
    }
fi


h=`date +%H`

if [ $h -lt 12 ]; then
  echo "Good Morning Jose!"
elif [ $h -lt 18 ]; then
  echo "Good Afternoon Jose!"
else
  echo "Good Evening Jose!"
fi
echo

# [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

if [[ "$(uname)" == "Darwin" ]]; then
    . $HOMEBREW_PREFIX/etc/profile.d/z.sh
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    # Do something under GNU/Linux platform
elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
    # Do something under 32 bits Windows NT platform
elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
    # Do something under 64 bits Windows NT platform
fi

# tabtab source for packages
# uninstall by removing these lines
[ -f ~/.config/tabtab/__tabtab.bash ] && . ~/.config/tabtab/__tabtab.bash || true



# check direnv
[ "$(command -v direnv)" ] && eval "$(direnv hook zsh)"

eval "$(ssh-agent -s)"
[ -s  ~/.ssh/id_ed25519 ] && ssh-add ~/.ssh/id_ed25519
