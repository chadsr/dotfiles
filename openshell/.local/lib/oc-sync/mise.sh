#!/bin/sh
# Trust and install the repository's mise tools. $1 workdir.
cd "$1" || exit
command -v mise >/dev/null && mise trust && mise install
