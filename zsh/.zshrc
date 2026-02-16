#!/usr/bin/env bash

# zmodload zsh/zprof

# shellcheck source=.aliases
source "$HOME"/.aliases

eval "$(fnm env --use-on-cd --shell zsh)"

# preserve delete key
bindkey "\\e[3~" delete-char

# preserve back/forward words with Ctrl + <-/->
bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word

# preserve home/end functionality for lines
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line

if [[ $(command -v starship) ]]; then
    eval "$(starship init zsh)"
else
    echo "starship not installed!"
fi

export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE="20"

# ZSH Plugins
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    [ -s /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh ] && \. /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
    [ -s /usr/share/zsh/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh ] && \. /usr/share/zsh/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh

    # zsh-syntax-highlighting must be loaded last
    [ -s /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \. /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
elif [[ "$OSTYPE" == "darwin"* ]]; then
    [ -s "$HOMEBREW_PREFIX/share/zsh-completions" ] && FPATH="$HOMEBREW_PREFIX/share/zsh-completions:$FPATH"
    [ -s "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && \. "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    [ -s "$HOMEBREW_PREFIX/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh" ] && \. "$HOMEBREW_PREFIX/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh"

    # zsh-syntax-highlighting must be loaded last
    [ -s "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && \. "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

    # OPT + <-/->
    bindkey "^[^[[C" forward-word
    bindkey "^[^[[D" backward-word

    # fixes GPG smart card availability
    gpg --card-status >/dev/null
fi

# zprof
