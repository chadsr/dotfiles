#!/usr/bin/env zsh

# shellcheck shell=bash

# User configuration

# shellcheck source=.aliases
source "$HOME"/.aliases

eval "$(thefuck --alias)"
eval "$(thefuck --alias fuck)"

# NVM Init
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    source /usr/share/nvm/init-nvm.sh
elif [[ "$OSTYPE" == "darwin"* ]]; then
    [ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"                                       # This loads nvm
    [ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" # This loads nvm bash_completion

    # fixes GPG smart card availability
    gpg --card-status >/dev/null
fi

eval "$(starship init zsh)"
