#!/usr/bin/env bash

BASE_PATH=$PWD

SIGN_KEY=0xA6C9F349967F1AC6
RECIPIENT_KEY=0x79C70BBE4865D828

set -euo pipefail
trap 'echo "Error!"' ERR INT

gpg_encrypt() {
    gpg --default-key "$SIGN_KEY" --recipient "$RECIPIENT_KEY" --armor --output "${2}" --sign --encrypt "${1}"
}

gpg --import ./data/gpg/2B7340DB13C85766.asc

gpg_encrypt ~/.ssh/config "$BASE_PATH"/data/ssh/config.asc.gpg
gpg_encrypt ~/.config/tidal-hifi/config.json "$BASE_PATH"/data/tidal-hifi/config.json.asc.gpg
