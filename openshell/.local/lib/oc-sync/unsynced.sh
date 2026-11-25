#!/bin/sh
# Tree and HEAD of the checkout, one per line: what unsynced work is measured against. $1 workdir.
cd "$1" || exit
git add -A && git write-tree && git rev-parse HEAD
