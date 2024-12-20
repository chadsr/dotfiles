#################################
# General Environment Variables #
#################################

############
#   GPG    #
############
CURRENT_TTY=$(tty)
export GPG_TTY=$CURRENT_TTY

##########
#  Ruby  #
##########
export GEM_HOME=$HOME/.gem
GEM_BIN=$(gem environment gemdir)/bin
export PATH=$PATH:$GEM_BIN

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    LINUX_ASKPASS=$(which wayprompt-ssh-askpass)
    export SSH_ASKPASS=$LINUX_ASKPASS

    # Export env vars from systemd user units
    # shellcheck disable=SC1090,SC1091
    source <(systemctl --user show-environment | sed 's/ //g; s/^/export /')

    export BEMENU_OPTS="-n -m -1 --nb #000b1ecc --tb #000b1ecc --tf #ea00d9ff --nf #0abdc6ff"

    ############
    #  Golang  #
    ############
    export GOPATH=$HOME/go
    export GOROOT=/usr/lib/go
    export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
    export GO111MODULE=on

    ############
    #   Rust   #
    ############
    CARGO_BIN=$HOME/.cargo/bin
    export PATH=$CARGO_BIN:$PATH

    ###########
    # Android #
    ###########
    export ANDROID_HOME=$HOME/Android
    export ANDROID_USER_HOME=$HOME/.android
    ANDROID_STUDIO=$(which android-studio)
    export CAPACITOR_ANDROID_STUDIO_PATH=$ANDROID_STUDIO
    export PATH=$PATH:$ANDROID_HOME/tools
    export PATH=$PATH:$ANDROID_HOME/tools/bin
    export PATH=$PATH:$ANDROID_HOME/platform-tools
    export PATH=$PATH:$ANDROID_HOME/emulator

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
    export PATH=$NPM_CONFIG_PREFIX/bin:$PATH

    NODE_PATH=$(npm root -g)
    export NODE_PATH=${NODE_PATH}

    export NVM_DIR="$HOME/.nvm"
    # shellcheck disable=SC1091
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
    # shellcheck disable=SC1091
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

    ############
    #  Python  #
    ############
    export PYDEVD_CONTAINER_RANDOM_ACCESS_MAX_ITEMS=1000

    ############
    #  Conda   #
    ############
    export PATH=$PATH:/opt/anaconda/bin
    export PATH=$PATH:/opt/miniconda3/bin
    export CONDA_AUTO_ACTIVATE_BASE=false

    ##########
    #  Perl  #
    ##########
    export PATH=$PATH:/usr/bin/vendor_perl
    export PATH=$PATH:/usr/bin/core_perl

    ################
    #    Other     #
    ################
    export PATH=$PATH:/opt/brother/scanner/brscan5
    export AMDGPU_TARGETS="gfx1030"

elif [[ "$OSTYPE" == "darwin"* ]]; then
    LOCAL_BIN=$HOME/.local/bin
    export PATH=$PATH:$LOCAL_BIN

    MAC_ASKPASS=$(which ssh-askpass)
    export SSH_ASKPASS=$MAC_ASKPASS

    export PATH="$HOMEBREW_PREFIX/opt/ruby/bin:$PATH"
fi
