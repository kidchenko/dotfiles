REPO=${REPO:-kidchenko/dotfiles}
DOTFILES_DIR=${DOTFILES_DIR:-~/.${REPO}}

if [[ -f "$DOTFILES_DIR/tools/update.sh" ]]; then
    echo "I will load update"
    {
        source "$DOTFILES_DIR/tools/update.sh" &&
    } || {
        echo "fail load update"
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
. $(brew --prefix)/etc/profile.d/z.sh

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# tabtab source for packages
# uninstall by removing these lines
[ -f ~/.config/tabtab/__tabtab.bash ] && . ~/.config/tabtab/__tabtab.bash || true

eval "$(direnv hook zsh)"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519


#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/Users/josebarbosa/.sdkman"
[[ -s "/Users/josebarbosa/.sdkman/bin/sdkman-init.sh" ]] && source "/Users/josebarbosa/.sdkman/bin/sdkman-init.sh"

export GOPATH=/usr/local/bin/go
[[ /usr/local/bin/kubectl ]] && source <(kubectl completion zsh)

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"
export PATH="$PATH:$HOME/.gem/ruby/2.7.0/bin"
export PATH="/usr/local/opt/libpq/bin:$PATH"
