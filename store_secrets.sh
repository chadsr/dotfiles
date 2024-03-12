#!/usr/bin/env bash

GPG_SIGNING_KEY=0xA6C9F349967F1AC6
RECIPIENT_GPG_ENCRYPTION_KEY=0x79C70BBE4865D828

data_dir="./data"

laptop_name="laptop"
desktop_name="workstation"

exit_script() {
    rv=$?
    echo "Exiting..."
    exit $rv
}

set -euo pipefail
trap 'exit_script' ERR INT

script_name=$(basename "$0")
help() {
    printf "Stores configuration secrets to \"%s\".\n\nUsage: %s <laptop|workstaton>\n" "$data_dir" "$script_name"
}

gpg_encrypt_file() {
    gpg -v --local-user "$GPG_SIGNING_KEY" --recipient "$RECIPIENT_GPG_ENCRYPTION_KEY" --armor --sign --yes --output "${2}" --encrypt "${1}"
}

gpg_encrypt_dir() {
    gpgtar -v --gpg-args "--local-user ${GPG_SIGNING_KEY} --recipient ${RECIPIENT_GPG_ENCRYPTION_KEY}" --sign --output "${2}" --encrypt "${1}"
}

if [ "$#" -ne 1 ]; then
    help
    exit 0
fi

if [[ "$1" != "$laptop_name" ]] && [[ "$1" != "$desktop_name" ]]; then
    help
    exit 1
fi

gpg --import "$data_dir"/gpg/2B7340DB13C85766.asc

# Shared Files
gpg_encrypt_file ~/.ssh/config "$data_dir"/ssh/config.asc.gpg
gpg_encrypt_file ~/.config/mimeapps.list "$data_dir"/xdg/mimeapps.list.asc.gpg
gpg_encrypt_file ~/.config/tidal-hifi/config.json "$data_dir"/tidal-hifi/config.json.asc.gpg
gpg_encrypt_file ~/.config/gallery-dl/config.json "$data_dir"/gallery-dl/config.json.asc.gpg
gpg_encrypt_file ~/.config/waybar/modules/crypto/config.ini "$data_dir"/waybar/crypto/config.ini.asc.gpg
gpg_encrypt_file ~/.config/gtk-3.0/bookmarks "$data_dir"/gtk/bookmarks.asc.gpg

# Hardware-Specific Files
if [[ "$1" == "$laptop_name" ]]; then
    gpg_encrypt_dir ~/.config/corectrl/profiles "$data_dir"/corectrl/laptop_profiles.gpgtar
elif [[ "$1" == "$desktop_name" ]]; then
    gpg_encrypt_dir ~/.config/corectrl/profiles "$data_dir"/corectrl/workstation_profiles.gpgtar

fi
