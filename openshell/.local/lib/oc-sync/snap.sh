#!/bin/sh
# Sandbox side of a pull: the changes become one patch and the commits the host lacks a bundle, both in .oc-sync-out. $1 workdir, $2 tree recorded at push, $3 host commit at push.
set -e
cd "$1"
grep -qxF /.oc-sync-out/ .git/info/exclude 2>/dev/null || echo /.oc-sync-out/ >>.git/info/exclude
git add -A
now=$(git write-tree)
c=$(git rev-parse HEAD)
rm -rf .oc-sync-out
mkdir .oc-sync-out
echo "$now $c" >.oc-sync-out/.oc-sync-head
# Each submodule directory: its edits since its baseline become a patch of its own.
n=$(cat .oc-sync-out/n 2>/dev/null || echo 0)
find . -name oc-sync-base | while IFS= read -r m; do
  r=${m%/.git/oc-sync-base}
  b=$(cat "$m")
  git -C "$r" add -A
  sub=$(git -C "$r" write-tree)
  [ "$sub" = "$b" ] && continue
  n=$((n + 1))
  echo "$n" >.oc-sync-out/n
  mkdir -p ".oc-sync-out/sub/$n"
  echo "$r" >".oc-sync-out/sub/$n/path"
  git -C "$r" diff --binary --full-index --no-renames "$b" "$sub" >".oc-sync-out/sub/$n/patch"
done
[ "$now" = "$2" ] && [ "$c" = "$3" ] && [ ! -d .oc-sync-out/sub ] && exit 0
git diff --name-status --no-renames "$2" "$now" >.oc-sync-out/changes
git diff --binary --full-index --no-renames "$2" "$now" >.oc-sync-out/worktree.patch
if ! git merge-base --is-ancestor HEAD "$3" 2>/dev/null; then
  # The bundle leaves out the history the host already has when its branch can fast-forward ("ff" says so).
  if git merge-base --is-ancestor "$3" HEAD 2>/dev/null; then
    git bundle create .oc-sync-out/repo.bundle HEAD "^$3"
    echo ff >>.oc-sync-out/.oc-sync-head
  else
    git bundle create .oc-sync-out/repo.bundle HEAD
  fi
fi
