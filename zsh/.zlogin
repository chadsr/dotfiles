# shellcheck shell=bash

# warm gpg agent for the LOCAL card; skipped when a forwarded agent is active
if [[ "$OSTYPE" == "darwin"* && -z "${GNUPGHOME:-}" ]]; then
  gpg --card-status >/dev/null 2>&1
fi
