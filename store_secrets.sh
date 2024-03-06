#!/usr/bin/env bash

GPG_SIGNING_KEY=0xA6C9F349967F1AC6
RECIPIENT_GPG_ENCRYPTION_KEY=0x79C70BBE4865D828

set -euo pipefail
trap 'echo "Error!"' ERR INT

gpg_encrypt_file() {
    gpg -v --local-user "$GPG_SIGNING_KEY" --recipient "$RECIPIENT_GPG_ENCRYPTION_KEY" --armor --sign --output "${2}" --encrypt "${1}"
}

gpg_encrypt_dir() {
    gpgtar -v --gpg-args "--local-user ${GPG_SIGNING_KEY} --recipient ${RECIPIENT_GPG_ENCRYPTION_KEY}" --sign --output "${2}" --encrypt "${1}"
}

gpg --import ./data/gpg/2B7340DB13C85766.asc

# Files
gpg_encrypt_file ~/.ssh/config ./data/ssh/config.asc.gpg
gpg_encrypt_file ~/.config/mimeapps.list ./data/xdg/mimeapps.list.asc.gpg
gpg_encrypt_file ~/.config/tidal-hifi/config.json ./data/tidal-hifi/config.json.asc.gpg
gpg_encrypt_file ~/.config/gallery-dl/config.json ./data/gallery-dl/config.json.asc.gpg

# Directories
gpg_encrypt_dir ./corectrl/.config/corectrl/profiles ./data/corectrl/profiles.gpgtar
