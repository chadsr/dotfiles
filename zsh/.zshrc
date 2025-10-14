#!/usr/bin/env zsh

# shellcheck shell=bash

# User configuration

# shellcheck source=.aliases
source "$HOME"/.aliases

eval "$(thefuck --alias)"
eval "$(thefuck --alias fuck)"

# NVM Init
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    [ -s /usr/share/nvm/init-nvm.sh ] && \. /usr/share/nvm/init-nvm.sh
elif [[ "$OSTYPE" == "darwin"* ]]; then
    [ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"                                       # This loads nvm
    [ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" # This loads nvm bash_completion

    # fixes GPG smart card availability
    gpg --card-status >/dev/null
fi

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    [ -s /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \. /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    [ -s /usr/share/zsh/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh ] && \. /usr/share/zsh/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh
    [ -s /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh ] && \. /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
elif [[ "$OSTYPE" == "darwin"* ]]; then
    [ -s "$HOMEBREW_PREFIX/share/zsh-completions" ] && FPATH="$HOMEBREW_PREFIX/share/zsh-completions:$FPATH"
    [ -s "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && \. "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    [ -s "$HOMEBREW_PREFIX/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh" ] && \. "$HOMEBREW_PREFIX/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh"
    [ -s "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && \. "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# preserve back/forward words with Ctrl + <-/->
bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word

if [[ $(command -v starship) ]]; then
    eval "$(starship init zsh)"
else
    echo "starship not installed!"
fi
