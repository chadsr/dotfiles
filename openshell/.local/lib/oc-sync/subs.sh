#!/bin/sh
# Sandbox side of a push: a submodule is a plain directory; the parent keeps the gitlink but skips the path, and an empty repo in the directory holds the baseline. $1 workdir.
set -e
cd "$1"
find . -name .git -type f -delete
git ls-files --stage | grep "^160000" | cut -f2- | while IFS= read -r p; do
  git update-index --skip-worktree "$p"
  mkdir -p "$p"
  git -C "$p" init -q
  git -C "$p" add -A
  git -C "$p" write-tree >"$p/.git/oc-sync-base"
done
