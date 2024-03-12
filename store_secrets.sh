#!/usr/bin/env bash

GPG_SIGNING_KEY=0xA6C9F349967F1AC6
RECIPIENT_GPG_ENCRYPTION_KEY=0x79C70BBE4865D828

base_path=$PWD
data_path="$base_path"/data

laptop_hostname="thinky"
desktop_hostname="shifty"
current_hostname=$(hostname)

exit_script() {
    rv=$?
    printf "\n\nExiting...\n"
    exit $rv
}

set -euo pipefail
trap 'exit_script' ERR INT

script_name=$(basename "$0")
help() {
    printf "Stores configuration secrets to \"%s\".\n\nUsage: %s <%s|%s>\n" "$data_path" "$script_name" "$laptop_hostname" "$desktop_hostname"
}

gpg_encrypt_file() {
    gpg -v --local-user "$GPG_SIGNING_KEY" --recipient "$RECIPIENT_GPG_ENCRYPTION_KEY" --armor --sign --yes --output "${2}" --encrypt "${1}"
}

gpg_encrypt_dir() {
    gpgtar -v --gpg-args "--local-user ${GPG_SIGNING_KEY} --recipient ${RECIPIENT_GPG_ENCRYPTION_KEY} --yes" --sign --directory "${1}" --output "${3}" --encrypt "${2}"
}

if [[ "$current_hostname" != "$laptop_hostname" ]] && [[ "$current_hostname" != "$desktop_hostname" ]]; then
    if [[ "$1" != "$laptop_hostname" ]] && [[ "$1" != "$desktop_hostname" ]]; then
        echo "Unrecognised hostname! Please provide a valid one."
        help
        exit 1
    else
        echo "Unrecognised hostname. Falling back to provided parameter: \"${1}\"."
        current_hostname="$1"
    fi
else
    echo "Using current hostname \"${current_hostname}\" for configuration."
fi

gpg --import "$data_path"/gpg/2B7340DB13C85766.asc

# Shared Files
gpg_encrypt_file ~/.ssh/config "$data_path"/ssh/config.asc.gpg
gpg_encrypt_file ~/.config/mimeapps.list "$data_path"/xdg/mimeapps.list.asc.gpg
gpg_encrypt_file ~/.config/tidal-hifi/config.json "$data_path"/tidal-hifi/config.json.asc.gpg
gpg_encrypt_file ~/.config/gallery-dl/config.json "$data_path"/gallery-dl/config.json.asc.gpg
gpg_encrypt_file ~/.config/waybar/modules/crypto/config.ini "$data_path"/waybar/crypto/config.ini.asc.gpg
gpg_encrypt_file ~/.config/gtk-3.0/bookmarks "$data_path"/gtk/bookmarks.asc.gpg

# Hardware-Specific Files
if [[ "$current_hostname" == "$laptop_hostname" ]]; then
    gpg_encrypt_dir ~/.config/corectrl profiles/ "$data_path"/corectrl/"$laptop_hostname"_profiles.gpgtar
elif [[ "$current_hostname" == "$desktop_hostname" ]]; then
    gpg_encrypt_dir ~/.config/corectrl profiles/ "$data_path"/corectrl/"$desktop_hostname"_profiles.gpgtar

fi
