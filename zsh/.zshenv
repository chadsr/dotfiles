#################################
# General Environment Variables #
#################################

# Add any local binaries to PATH
export PATH=$PATH:$HOME/.local/bin

################################
# Golang Environment Variables #
################################
export GOPATH=$HOME/go
export GOROOT=/usr/lib/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

# Enable Go modules by default
export GO111MODULE=on

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

NPM_PACKAGES="${HOME}/.npm-packages"
export PATH="$NPM_PACKAGES/bin:$PATH"

# Unset manpath so we can inherit from /etc/manpath via the `manpath` command
unset MANPATH # delete if you already modified MANPATH elsewhere in your config
export MANPATH="$NPM_PACKAGES/share/man:$(manpath)"

#################
# Gnome Keyring #
#################

# Start the Gnome Keyring Daemon for headless zsh sessions
if [ -n "$DESKTOP_SESSION" ]; then
    eval "$(gnome-keyring-daemon --start)"
    export SSH_AUTH_SOCK
fi
