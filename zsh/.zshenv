export PATH=$PATH:$HOME/.local/bin

export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

export ELECTRON_TRASH=gio

export GEM_HOME=$HOME/.gem
export PATH=$PATH:$GEM_HOME/ruby/2.6.0/bin

# Start the Gnome Keyring Daemon
if [ -n "$DESKTOP_SESSION" ];then
    eval $(gnome-keyring-daemon --start)
    export SSH_AUTH_SOCK
fi