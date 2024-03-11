#################################
# General Environment Variables #
#################################

# Set default editor
export EDITOR=/usr/bin/nvim
export VISUAL=/usr/bin/nvim

# XDG
XDG_SCREENSHOTS_DIR=$HOME/Pictures/screenshots
XDG_CONFIG_HOME=$HOME/.config

# Add any local binaries to PATH
export PATH=$PATH:$HOME/.local/bin

# Conda
export PATH=$PATH:/opt/anaconda/bin
export PATH=$PATH:/opt/miniconda3/bin
export CONDA_AUTO_ACTIVATE_BASE=false

# Android
export PATH=$PATH:/opt/android-sdk/platform-tools
export PATH=$PATH:/opt/android-sdk/emulator

################################
# Golang Environment Variables #
################################
export GOPATH=$HOME/go
export GOROOT=/usr/lib/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

# Enable Go modules by default
export GO111MODULE=on

################################
# Rust Environment Variables #
################################
CARGO_BIN=$HOME/.cargo/bin
export PATH=$CARGO_BIN:$PATH

############
#   Vim    #
############

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
    export EDITOR='vim'
else
    export EDITOR='nvim'
fi

############
# Electron #
############

# Fixes moving files to trash in electron apps
export ELECTRON_TRASH=gio

##############################
# Ruby Environment Variables #
##############################

export GEM_HOME=$HOME/.gem
export PATH=$PATH:$GEM_HOME/ruby/2.6.0/bin

#################################
# Node.js Environment Variables #
#################################

NPM_CONFIG_PREFIX=~/.npm-global
export PATH=$NPM_CONFIG_PREFIX/bin:$PATH

NODE_PATH=$(npm root -g)
export NODE_PATH=${NODE_PATH}

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

################
# Android/Java #
################

export _JAVA_AWT_WM_NONREPARENTING=1
export JAVA_HOME=/usr/lib/jvm/default
export ANDROID_HOME=$HOME/Android
export ANDROID_USER_HOME=$HOME/.android
export ANDROID_SDK_ROOT=$HOME/Android/Sdk
export ANDROID_EMULATOR_HOME=$ANDROID_USER_HOME

export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/platform-toolsexport ANDROID_USER_HOME=$HOME/.android

#################
#  GPG for SSH  #
#################
export GPG_TTY="$(tty)"
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
gpgconf --launch gpg-agent

# If it's a zsh terminal session, use curses for pinentry over the default GUI
export PINENTRY_USER_DATA="curses"

################
#    Other     #
################
export PATH=$PATH:/opt/brother/scanner/brscan5
export AMDGPU_TARGETS="gfx1030"
export CARGO_NET_GIT_FETCH_WITH_CLI=true
