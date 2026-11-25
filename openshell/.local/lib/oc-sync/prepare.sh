#!/bin/sh
# Sandbox side of a push: the checkout becomes a copy of the host's branch. $1 workdir, $2 branch, $3 commit to check out (FETCH_HEAD after fetching the bundle, else one already there).
set -e
t=$1
if [ "$3" = FETCH_HEAD ]; then
  [ -d "$t/.git" ] || git init -q "$t"
  git -C "$t" fetch -q /sandbox/.oc-sync/repo.bundle HEAD
fi
if [ "$2" = HEAD ]; then git -C "$t" checkout -q --detach "$3"; else git -C "$t" checkout -q -B "$2" "$3"; fi
grep -qxF /.oc-sync-out/ "$t/.git/info/exclude" 2>/dev/null || echo /.oc-sync-out/ >>"$t/.git/info/exclude"
rm -rf "$t/.oc-sync-out"
# A submodule arrives as plain files with a .git file that points nowhere here, so the previous plain copy (its repo included) goes first.
find "$t" -name .git -type f -delete
find "$t" -name oc-sync-base | while IFS= read -r m; do rm -rf "${m%/.git/oc-sync-base}/.git"; done
git -C "$t" reset -q --hard HEAD
git -C "$t" clean -qfd
