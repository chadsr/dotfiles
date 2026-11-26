#!/bin/sh
# Sandbox side of oc, sent as the text of sh -c ($0 is oc, then a command and its arguments).
set -e
cmd=$1
shift

case "$cmd" in
# Make the checkout a copy of the host's branch. $1 workdir, $2 branch (HEAD: detached), $3 commit or FETCH_HEAD
prepare)
  t=$1
  if [ "$3" = FETCH_HEAD ]; then
    [ -d "$t/.git" ] || git init -q "$t"
    # no submodule recursion: there are none here
    git -C "$t" fetch -q --no-recurse-submodules /sandbox/.oc-sync/repo.bundle HEAD
  fi
  if [ "$2" = HEAD ]; then git -C "$t" checkout -q -f --detach "$3"; else git -C "$t" checkout -q -f -B "$2" "$3"; fi
  grep -qxF /.oc-sync-out/ "$t/.git/info/exclude" 2>/dev/null || echo /.oc-sync-out/ >>"$t/.git/info/exclude"
  rm -rf "$t/.oc-sync-out"
  # A submodule arrives as plain files: remove the previous copy first.
  git -c core.quotePath=false -C "$t" ls-files --stage | grep "^160000" | cut -f2- | while IFS= read -r p; do rm -rf "${t:?}/${p:?}"; done
  git -C "$t" reset -q --hard HEAD
  git -C "$t" clean -qfd
  ;;
# Remove the .git files submodules arrive with: they point nowhere here. $1 workdir
subs)
  cd "$1"
  find . -name .git -type f -delete
  ;;
# Tree of the worktree with every change staged; the index goes back to HEAD. $1 workdir
tree)
  cd "$1"
  git add -A && git write-tree && git reset -q
  ;;
# The same tree and HEAD, one per line. $1 workdir
unsynced)
  cd "$1"
  git add -A && git write-tree && git rev-parse HEAD
  ;;
# Write the patch and the bundle for the host to .oc-sync-out. $1 workdir, $2 tree at push, $3 host commit at push
snap)
  cd "$1"
  grep -qxF /.oc-sync-out/ .git/info/exclude 2>/dev/null || echo /.oc-sync-out/ >>.git/info/exclude
  git add -A
  now=$(git write-tree)
  c=$(git rev-parse HEAD)
  rm -rf .oc-sync-out
  mkdir .oc-sync-out
  echo "$now $c" >.oc-sync-out/.oc-sync-head
  [ "$now" = "$2" ] && [ "$c" = "$3" ] && exit 0
  git diff --name-status --no-renames "$2" "$now" >.oc-sync-out/changes
  git diff --binary --full-index --no-renames "$2" "$now" >.oc-sync-out/worktree.patch
  if ! git merge-base --is-ancestor HEAD "$3" 2>/dev/null; then
    # The host can fast-forward: bundle only the new commits and say so with "ff".
    if git merge-base --is-ancestor "$3" HEAD 2>/dev/null; then
      git bundle create .oc-sync-out/repo.bundle HEAD "^$3"
      echo ff >>.oc-sync-out/.oc-sync-head
    else
      git bundle create .oc-sync-out/repo.bundle HEAD
    fi
  fi
  ;;
# Write the layout marker. $1 marker text
marker)
  printf "%s\n" "$1" >/sandbox/.oc-layout
  ;;
marker-read)
  cat /sandbox/.oc-layout 2>/dev/null || echo none
  ;;
# Whether the workdir holds a checkout: yes or no. $1 workdir
has-checkout)
  if [ -d "$1/.git" ]; then echo yes; else echo no; fi
  ;;
# Trust and install the repository's mise tools. $1 workdir
mise)
  cd "$1"
  command -v mise >/dev/null && mise trust && mise install
  ;;
*)
  echo "unknown command: $cmd" >&2
  exit 1
  ;;
esac
