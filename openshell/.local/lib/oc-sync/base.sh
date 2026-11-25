#!/bin/sh
# Sandbox side of a pull: every submodule baseline moves to what was just pulled. $1 workdir.
set -e
cd "$1"
find . -name oc-sync-base | while IFS= read -r m; do
  r=${m%/.git/oc-sync-base}
  git -C "$r" add -A
  git -C "$r" write-tree >"$m"
done
