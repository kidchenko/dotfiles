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

fpath=(/usr/local/share/zsh-completions $fpath)
[ -s $(brew --prefix)/etc/profile.d/z.sh ] && . $(brew --prefix)/etc/profile.d/z.sh

# tabtab source for packages
# uninstall by removing these lines
[ -f ~/.config/tabtab/__tabtab.bash ] && . ~/.config/tabtab/__tabtab.bash || true

# check direnv
[ "$(command -v direnv)" ] && eval "$(direnv hook zsh)"

eval "$(ssh-agent -s)"
[ -s  ~/.ssh/id_ed25519 ] && ssh-add ~/.ssh/id_ed25519

. /usr/local/etc/profile.d/z.sh
