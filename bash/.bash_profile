# shellcheck shell=bash

# shellcheck source=../zsh/.zprofile
if [ -r "$HOME/.zprofile" ]; then
  # shellcheck source=../zsh/.zprofile
  . "$HOME/.zprofile"
fi

# shellcheck source=.bashrc
case "$-" in *i*) if [ -r ~/.bashrc ]; then . ~/.bashrc; fi ;; esac
