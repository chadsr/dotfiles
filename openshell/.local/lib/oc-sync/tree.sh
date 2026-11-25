#!/bin/sh
# Tree of the worktree with every change staged; the index goes back to HEAD. $1 workdir.
cd "$1" || exit
git add -A && git write-tree && git reset -q
