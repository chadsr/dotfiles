# shellcheck shell=bash

# shellcheck source=.bashrc
case "$-" in *i*) if [ -r ~/.bashrc ]; then . ~/.bashrc; fi ;; esac
