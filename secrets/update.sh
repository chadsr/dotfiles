#!/usr/bin/env bash
# secrets/update.sh — single secrets management script.
#
# Default mode: update runtime changes back into the encrypted sops store.
#   For each secret with a `path` in secrets/manifest.nix, compares the deployed
#   file against the sops value; if changed, re-encrypts the update.
#
# Usage:
#   ./secrets/update.sh             # update runtime changes (run after edits)
#   ./secrets/update.sh --init      # one-time initial population
#
# Requires: sops, gpg, jq, nix, openssl, mkpasswd (whois) or openssl passwd.

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
SOPS_FILE="secrets/secrets.yaml"

need() { command -v "$1" >/dev/null 2>&1 || {
  echo "missing required tool: $1" >&2
  exit 1
}; }
need sops
need jq
need nix

echo "==> Preflight"
if ! sops -d "$SOPS_FILE" >/dev/null 2>&1; then
  echo "ERROR: cannot decrypt $SOPS_FILE (Yubikey present + gpg-agent running?)" >&2
  exit 1
fi
echo "  sops decrypt OK"

# ---------------------------------------------------------------------------
# --init: one-time bootstrap from the former .asc.gpg files.
# ---------------------------------------------------------------------------
do_init() {
  need openssl
  need gpg

  set_secret() {
    local key="$1" val="$2"
    sops --set "$(jq -nc --arg k "$key" --arg v "$val" '[$k, $v]')" "$SOPS_FILE"
    echo "  set: $key"
  }

  echo "==> Init: generating LUKS recovery secrets"
  set_secret "luks-root-passphrase" "$(openssl rand -base64 32)"
  set_secret "luks-secondary-keyfile" "$(openssl rand -base64 48)"

  echo "==> Init: marvin login password"
  read -rsp "Enter marvin's login password: " pw1
  echo
  read -rsp "Confirm password: " pw2
  echo
  if [ "$pw1" != "$pw2" ]; then
    echo "passwords did not match" >&2
    exit 1
  fi
  if command -v mkpasswd >/dev/null 2>&1; then
    set_secret "marvin-hashed-password" "$(mkpasswd -m yescrypt "$pw1")"
  else
    set_secret "marvin-hashed-password" "$(openssl passwd -6 "$pw1")"
  fi

  echo
  echo "==> Init complete."
  echo "    Commit: git add secrets/secrets.yaml && git commit -m 'secrets: init'"
}

# ---------------------------------------------------------------------------
# Default: update runtime changes.
# ---------------------------------------------------------------------------
do_update() {
  echo "==> Reading manifest"
  SECRETS=$(nix eval --extra-experimental-features 'nix-command' --json --file secrets/manifest.nix 2>/dev/null |
    jq -r 'to_entries[] | select(.value.path != null) | "\(.key)\t\(.value.path)"')

  if [ -z "$SECRETS" ]; then
    echo "No path-bearing secrets found in manifest."
    exit 0
  fi

  count=$(echo "$SECRETS" | wc -l)
  echo "  $count path-bearing secrets to check"

  updated=0
  unchanged=0
  skipped=0
  tmp_current=$(mktemp)
  tmp_sops=$(mktemp)
  trap 'rm -f "$tmp_current" "$tmp_sops"' EXIT

  while IFS=$'\t' read -r key target; do
    [ -z "$key" ] && continue

    # Skip if the target file doesn't exist (not deployed on this host).
    if [ ! -f "$target" ]; then
      echo "  skip (missing): $key"
      skipped=$((skipped + 1))
      continue
    fi

    # Skip binary files (java keystores, ed25519 keys, etc.).
    if grep -qP '\x00' "$target" 2>/dev/null; then
      echo "  skip (binary): $key"
      skipped=$((skipped + 1))
      continue
    fi

    # Read the current file content.
    cat "$target" >"$tmp_current"

    # Decrypt the sops-stored value for this key.
    key_path=$(jq -nc --arg k "$key" '[$k]')
    if ! sops -d --extract "$key_path" "$SOPS_FILE" >"$tmp_sops" 2>/dev/null; then
      echo "  skip (decrypt failed): $key"
      skipped=$((skipped + 1))
      continue
    fi

    # Compare — diff handles trailing-newline edge cases cleanly.
    if diff -q "$tmp_current" "$tmp_sops" >/dev/null 2>&1; then
      unchanged=$((unchanged + 1))
      continue
    fi

    # Changed — re-encrypt the updated content back into sops.
    current_value=$(cat "$tmp_current")
    sops --set "$(jq -nc --arg k "$key" --arg v "$current_value" '[$k, $v]')" "$SOPS_FILE"
    echo "  updated: $key → $target"
    updated=$((updated + 1))
  done <<<"$SECRETS"

  echo
  echo "==> Done: $updated updated, $unchanged unchanged, $skipped skipped."
  if [ "$updated" -gt 0 ]; then
    echo
    echo "Commit the updated store:"
    echo "  git add secrets/secrets.yaml && git commit -m 'secrets: update runtime changes'"
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
case "${1:-}" in
--init)
  do_init
  ;;
"" | --update)
  do_update
  ;;
*)
  echo "Usage: $0 [--init|--update]"
  echo "  (default) --update  detect + re-encrypt changed deployed files"
  echo "  --init              new initial values"
  exit 1
  ;;
esac
