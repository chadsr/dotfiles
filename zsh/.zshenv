# shellcheck shell=bash
# also sourced in .bash_env, so conform to bash syntax

# remove duplicate entries from $PATH
# zsh uses $path array along with $PATH
# shellcheck disable=SC2034
typeset -U PATH path

#################################
# General Environment Variables #
#################################

export HISTFILE=~/.zsh_history
export HISTSIZE=10000
export SAVEHIST=10000

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

  LINUX_ASKPASS=$(which wayprompt-ssh-askpass)
  export SSH_ASKPASS="$LINUX_ASKPASS"

  # Export env vars from systemd user units
  while IFS='=' read -r _sd_env_key _sd_env_val; do
    case "$_sd_env_key" in
    '' | SSH_AUTH_SOCK | GNUPGHOME) ;;
    *) export "$_sd_env_key=$_sd_env_val" ;;
    esac
  done < <(systemctl --user show-environment 2>/dev/null)
  unset _sd_env_key _sd_env_val

  export BEMENU_OPTS="-n -m -1 --nb #000b1ecc --tb #000b1ecc --tf #ea00d9ff --nf #0abdc6ff"

  ############
  #  Golang  #
  ############
  export GOPATH="$HOME/go"
  export GOROOT=/usr/lib/go
  export PATH="$GOPATH/bin:$GOROOT/bin:$PATH"
  export GO111MODULE=on

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
  ANDROID_STUDIO=$(which android-studio)
  export CAPACITOR_ANDROID_STUDIO_PATH="$ANDROID_STUDIO"
  export PATH="$ANDROID_HOME/tools:$PATH"
  export PATH="$ANDROID_HOME/tools/bin:$PATH"
  export PATH="$ANDROID_HOME/platform-tools:$PATH"
  export PATH="$ANDROID_HOME/emulator:$PATH"

  ############
  #   Vim    #
  ############
  export EDITOR=/usr/bin/nvim
  export VISUAL=/usr/bin/nvim

  # Preferred editor for remote sessions
  if [[ ! -z "${SSH_CONNECTION+x}" ]]; then
    if [[ ! -n "${SSH_CONNECTION}" ]]; then
      export EDITOR='vim'
    fi
  fi

  #############
  #  Node.js  #
  #############
  NPM_CONFIG_PREFIX=~/.npm-global
  export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"

  NODE_PATH=$(npm root -g)
  export NODE_PATH

  export NVM_DIR="$HOME/.nvm"

  ############
  #  Python  #
  ############
  export PYDEVD_CONTAINER_RANDOM_ACCESS_MAX_ITEMS=1000

  ############
  #  Conda   #
  ############
  export PATH="/opt/anaconda/bin:$PATH"
  export PATH="/opt/miniconda3/bin:$PATH"
  export CONDA_AUTO_ACTIVATE_BASE=false

  ##########
  #  Perl  #
  ##########
  export PATH="/usr/bin/vendor_perl:$PATH"
  export PATH="/usr/bin/core_perl:$PATH"

  ################
  #    Other     #
  ################
  export PATH="$HOME/.local/share/mise/shims:$PATH"
  export PATH="/opt/brother/scanner/brscan5:$PATH"
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

  MAC_ASKPASS=$(which ssh-askpass)
  export SSH_ASKPASS="$MAC_ASKPASS"

  export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
fi

##########
#  Ruby  #
##########
export GEM_HOME="$HOME/.gem"
GEM_BIN=$(gem environment gemdir)/bin
export PATH="$GEM_BIN:$PATH"
