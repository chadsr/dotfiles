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
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#ff00ff,bg=cyan,bold,underline"
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)

############
#   GPG    #
############
if [ -z ${TTY+x} ]; then
    DEFAULT_TTY=$(tty)
    export GPG_TTY=$DEFAULT_TTY
else
    export GPG_TTY=$TTY
fi

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    AGENT_SSH_SOCKET=$(gpgconf --list-dirs agent-ssh-socket)
    export SSH_AUTH_SOCK=AGENT_SSH_SOCKET
    gpg-connect-agent updatestartuptty /bye >/dev/null

    LINUX_ASKPASS=$(which wayprompt-ssh-askpass)
    export SSH_ASKPASS="$LINUX_ASKPASS"

    # Export env vars from systemd user units
    # shellcheck disable=SC1090,SC1091
    source <(systemctl --user show-environment | sed 's/ //g; s/^/export /')

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
    export NODE_PATH="${NODE_PATH}"

    YARN_BIN_PATH=$(yarn global bin)
    export PATH="$PATH:${YARN_BIN_PATH}"

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
    export PATH="/opt/brother/scanner/brscan5:$PATH"
    export AMDGPU_TARGETS="gfx1030"

elif [[ "$OSTYPE" == "darwin"* ]]; then
    # ignore global zsh configs, to prevent /etc/zprofile from calling path_helper and fucking up PATH order
    unsetopt GLOBAL_RCS
    source '/etc/zshrc' # still source /etc/zshrc for anything useful

    LOCAL_BIN="$HOME/.local/bin"
    export PATH="$LOCAL_BIN:$PATH"

    MAC_ASKPASS=$(which ssh-askpass)
    export SSH_ASKPASS="$MAC_ASKPASS"

    export PATH="$HOMEBREW_PREFIX/opt/ruby/bin:$PATH"
fi

##########
#  Ruby  #
##########
export GEM_HOME="$HOME/.gem"
GEM_BIN=$(gem environment gemdir)/bin
export PATH="$GEM_BIN:$PATH"
