# shellcheck shell=bash
# also sourced in .bash_env, so conform to bash syntax

# remove duplicate entries from $PATH
# zsh uses $path array along with $PATH
if [ -n "${ZSH_VERSION:-}" ]; then
  # shellcheck disable=SC2034
  typeset -U PATH path
fi

# repo root derived from this file's stow symlink
if [ -z "${DOTFILES:-}" ]; then
  _df_self=$(readlink -f "$HOME/.zshenv" 2>/dev/null) && export DOTFILES="${_df_self%/*/*}"
  unset _df_self
fi
[[ -n "${DOTFILES:-}" ]] && export PATH="$DOTFILES:$PATH"

#################################
# General Environment Variables #
#################################

export HISTFILE=~/.zsh_history
export HISTSIZE=10000
export SAVEHIST=10000

if [ -n "${SSH_CONNECTION:-}" ] && command -v infocmp >/dev/null 2>&1; then
  infocmp "${TERM:-}" >/dev/null 2>&1 || TERM=xterm-256color
fi

############
#   GPG    #
############
if [ -z ${TTY+x} ]; then
  DEFAULT_TTY=$(tty)
  export GPG_TTY=$DEFAULT_TTY
else
  export GPG_TTY=$TTY
fi

# ssh-forwarded gpg-agent; gpgconf finds the right socket path per OS
# (not yet on PATH here, hence the fallback locations)
_gpgconf=$(command -v gpgconf 2>/dev/null)
[[ -z "$_gpgconf" && -x /opt/homebrew/bin/gpgconf ]] && _gpgconf=/opt/homebrew/bin/gpgconf
[[ -z "$_gpgconf" && -x /usr/local/bin/gpgconf ]] && _gpgconf=/usr/local/bin/gpgconf
if [[ -n "${SSH_CONNECTION:-}" && -d "$HOME/.gnupg-forward" && -n "${_gpgconf:-}" ]]; then
  if [[ -S "$(GNUPGHOME="$HOME/.gnupg-forward" "$_gpgconf" --list-dir agent-socket 2>/dev/null)" ]]; then
    export GNUPGHOME="$HOME/.gnupg-forward"
  fi
fi
unset _gpgconf

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  if [[ -z "${GNUPGHOME:-}" ]]; then
    if [[ -z "$SSH_AUTH_SOCK" || ! -S "$SSH_AUTH_SOCK" ]]; then
      ssh_auth_sock=$(gpgconf --list-dirs agent-ssh-socket)
      [[ -S "$ssh_auth_sock" ]] && export SSH_AUTH_SOCK=$ssh_auth_sock
    fi
    [[ -n "${GPG_TTY:-}" ]] && gpg-connect-agent updatestartuptty /bye >/dev/null
  fi

  LINUX_ASKPASS=$(command -v wayprompt-ssh-askpass)
  export SSH_ASKPASS="$LINUX_ASKPASS"

  # session vars for non-graphical shells (ssh/tty)
  if [[ -z "${WAYLAND_DISPLAY:-}" && -z "${DISPLAY:-}" ]]; then
    while IFS='=' read -r _sd_env_key _sd_env_val; do
      export "$_sd_env_key=$_sd_env_val"
    done < <(systemctl --user show-environment 2>/dev/null |
      grep -E '^(DISPLAY|WAYLAND_DISPLAY|SWAYSOCK|HYPRLAND_INSTANCE_SIGNATURE|XDG_CURRENT_DESKTOP|XDG_SESSION_TYPE)=')
    unset _sd_env_key _sd_env_val
  fi

  # environment.d (~/.config + /etc) for every shell, via systemd's generator
  if [[ -x /usr/lib/systemd/user-environment-generators/30-systemd-environment-d-generator ]]; then
    set -a
    # shellcheck disable=SC1090
    source <(/usr/lib/systemd/user-environment-generators/30-systemd-environment-d-generator)
    set +a
  fi

  ############
  #  Golang  #
  ############
  export PATH="$HOME/go/bin:$PATH"

  ############
  #   Rust   #
  ############
  CARGO_BIN=$HOME/.cargo/bin
  export PATH="$CARGO_BIN:$PATH"

  ###########
  # Android #
  ###########
  export ANDROID_HOME="$HOME/Android"
  export ANDROID_USER_HOME="$HOME/.android"
  ANDROID_STUDIO=$(command -v android-studio)
  export CAPACITOR_ANDROID_STUDIO_PATH="$ANDROID_STUDIO"
  export PATH="$ANDROID_HOME/tools:$PATH"
  export PATH="$ANDROID_HOME/tools/bin:$PATH"
  export PATH="$ANDROID_HOME/platform-tools:$PATH"
  export PATH="$ANDROID_HOME/emulator:$PATH"

  #############
  #  Node.js  #
  #############
  NPM_CONFIG_PREFIX=~/.npm-global
  export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"

  ############
  #  Python  #
  ############
  export PYDEVD_CONTAINER_RANDOM_ACCESS_MAX_ITEMS=1000

  ##########
  #  Perl  #
  ##########
  export PATH="/usr/bin/vendor_perl:$PATH"
  export PATH="/usr/bin/core_perl:$PATH"

  ################
  #    Other     #
  ################
  export PATH="$HOME/.local/share/mise/shims:$PATH"
  export PATH="$HOME/.local/bin:$PATH"
  export DO_NOT_TRACK=1

elif [[ "$OSTYPE" == "darwin"* ]]; then
  # ignore global zsh configs, to prevent /etc/zprofile from calling path_helper and fucking up PATH order
  unsetopt GLOBAL_RCS

  # shellcheck disable=SC1091
  source '/etc/zshrc' # still source /etc/zshrc for anything useful

  export PATH="/opt/homebrew/bin:$PATH"
  export PATH="$HOME/.local/bin:$PATH"

  if [[ -z "${GNUPGHOME:-}" ]]; then
    if [[ -z "$SSH_AUTH_SOCK" || ! -S "$SSH_AUTH_SOCK" ]]; then
      ssh_auth_sock=$(gpgconf --list-dirs agent-ssh-socket)
      [[ -S "$ssh_auth_sock" ]] && export SSH_AUTH_SOCK=$ssh_auth_sock
    fi
    [[ -n "${GPG_TTY:-}" ]] && gpg-connect-agent updatestartuptty /bye >/dev/null
  fi

  MAC_ASKPASS=$(command -v ssh-askpass)
  export SSH_ASKPASS="$MAC_ASKPASS"

  export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
fi

##########
#  Ruby  #
##########
export GEM_HOME="$HOME/.gem"
GEM_BIN="$GEM_HOME/bin"
export PATH="$GEM_BIN:$PATH"

############
#  Editor  #
############
# placed after OS branches so command -v sees the full PATH
EDITOR="$(command -v nvim)"
VISUAL="$EDITOR"
export EDITOR VISUAL

# Preferred editor for remote sessions
if [[ ! -z "${SSH_CONNECTION+x}" ]]; then
  if [[ ! -n "${SSH_CONNECTION}" ]]; then
    export EDITOR='vim'
  fi
fi
