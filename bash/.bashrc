#!/usr/bin/env bash

source "$HOME"/.aliases

# Set GPG SSH Agent
unset SSH_AGENT_PID
if [ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]; then
    SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
    export SSH_AUTH_SOCK
fi
GPG_TTY=$(tty)
export GPG_TTY
gpg-connect-agent updatestartuptty /bye >/dev/null

# If stdin is a tty
if [ -t 0 ]; then
    # TTY, so set USER_TTY for pinentry-auto to pickup
    export PINENTRY_USER_DATA=USE_TTY=1
fi

# NVM Init
source /usr/share/nvm/init-nvm.sh
