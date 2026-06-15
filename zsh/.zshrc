#!/usr/bin/env bash

# zmodload zsh/zprof

##############
#  Keybinds  #
##############

# preserve delete key
bindkey "\\e[3~" delete-char

# preserve back/forward words with Ctrl + <-/->
bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word

# preserve home/end functionality for lines
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line

if [[ "$OSTYPE" == "darwin"* ]]; then
  # OPT + <-/->
  bindkey "^[^[[C" forward-word
  bindkey "^[^[[D" backward-word
fi

##########
#  Init  #
##########

if [[ $(command -v starship) ]]; then
  eval "$(starship init zsh)"
else
  echo "starship not installed!"
fi

#############
#  Plugins  #
#############

export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE="20"
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#ff00ff,bg=cyan,bold,underline"
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # shellcheck source=/dev/null
  [ -s /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh ] && \. /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
  # shellcheck source=/dev/null
  [ -s /usr/share/zsh/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh ] && \. /usr/share/zsh/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh

  # zsh-syntax-highlighting must be loaded last
  # shellcheck source=/dev/null
  [ -s /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \. /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
elif [[ "$OSTYPE" == "darwin"* ]]; then
  [ -s "$HOMEBREW_PREFIX/share/zsh-completions" ] && FPATH="$HOMEBREW_PREFIX/share/zsh-completions:$FPATH"
  # shellcheck source=/dev/null
  [ -s "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && \. "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  # shellcheck source=/dev/null
  [ -s "$HOMEBREW_PREFIX/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh" ] && \. "$HOMEBREW_PREFIX/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh"

  # zsh-syntax-highlighting must be loaded last
  # shellcheck source=/dev/null
  [ -s "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && \. "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

zstyle ':autocomplete:*' min-input 3 # minimum characters before autocomplete kicks in
zstyle ':autocomplete:*' delay 1.0   # delay before starting autocomplete after typing (seconds)

#############
#  Aliases  #
#############

# shellcheck source=.aliases
source "$HOME"/.aliases

# 'git <alias>' to 'g<alias>'/'git<alias>'
_git_alias_describe() {
  [[ $CURRENT -eq 1 ]] || return 1
  local -a pairs
  local n
  for n in "${_git_alias_names[@]}"; do
    [[ $n == "$PREFIX"* ]] || continue
    pairs+=("${n}: alias for: ${_git_alias_exp[$n]}")
  done
  ((${#pairs[@]})) || return 1
  _describe 'git alias' pairs
}

_git_alias_setup() {
  local -a prefixes=(g git) # shorthand prefixes
  typeset -gA _git_alias_exp=()
  typeset -ga _git_alias_names=()
  local line al exp sub p
  while IFS= read -r line; do
    al="${line%% *}"  # alias.<name>
    al="${al#alias.}" # <name>
    exp="${line#* }"  # value (may contain spaces / leading '!')
    sub="${exp%% *}"  # underlying git subcommand (unused for ! aliases)
    for p in "${prefixes[@]}"; do
      # shellcheck disable=SC2139 # expansion at definition time is intentional
      alias "${p}${al}"="git ${al}"
      _git_alias_exp[${p}${al}]="$exp"
      _git_alias_names+=("${p}${al}")
      [[ "$exp" != '!'* ]] && compdef "_git-${sub}" "${p}${al}"
    done
  done < <(git config --get-regexp '^alias\.')
  # Prepend _git_alias_describe so the shorthand names show their expansion in the menu
  local rest
  line=$(zstyle -L ':completion:*' completer)
  rest=${line#* completer }
  if [[ -n $rest ]]; then
    zstyle ':completion:*' completer _git_alias_describe "${=rest}"
  else
    zstyle ':completion:*' completer _git_alias_describe
  fi
}

autoload -Uz add-zsh-hook
_git_alias_setup_hook() {
  [[ -v _comp_setup ]] || return # compinit not done yet, retry next prompt
  add-zsh-hook -d precmd _git_alias_setup_hook
  _git_alias_setup
}
add-zsh-hook precmd _git_alias_setup_hook

###########
#  Tools  #
###########

if [[ "$OSTYPE" == "darwin"* ]]; then
  # fixes GPG smart card availability
  gpg --card-status >/dev/null
fi

if [[ $(command -v fnm) ]]; then
  eval "$(fnm env --use-on-cd --shell zsh)"
else
  echo "fnm not installed!"
fi

# zprof
