# shellcheck shell=bash

# remove the socket a client RemoteForward'ed into ~/.gnupg-forward for this session
if [[ -e "$HOME/.gnupg-forward/S.gpg-agent" ]]; then
  rm -f -- "$HOME/.gnupg-forward/S.gpg-agent"
fi
