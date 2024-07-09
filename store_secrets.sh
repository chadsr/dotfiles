#!/usr/bin/env bash

gpg_primary_key=0x2B7340DB13C85766
gpg_encryption_subkey=0x79C70BBE4865D828

pkglist_system_path=/etc/pkglist.txt

laptop_hostname="thinky"
desktop_hostname="shifty"
current_hostname=$(hostname)

tmp_path=/tmp/secrets-"$current_hostname"

exit_script() {
    rv=$?
    printf "\n\nExiting...\n"
    exit $rv
}

set -euo pipefail
trap 'exit_script' ERR INT

update_paths() {
    base_path=$PWD
    data_path="$base_path"/data
}

script_name=$(basename "$0")
update_paths

help() {
    printf "Stores configuration secrets to \"%s\".\n\nUsage: %s <%s|%s>\n" "$data_path" "$script_name" "$laptop_hostname" "$desktop_hostname"
}

diff_files() {
    if [[ ! -f "$1" ]] && [[ ! -L "$1" ]]; then
        echo "file ${1} does not exist"
        return 1
    fi
    if [[ ! -f "$1" ]] && [[ ! -L "$1" ]]; then
        echo "file ${2} does not exist"
        return 1
    fi

    vimdiff -d "$1" "$2" || {
        echo "vimdiff on ${1} <-> ${2}' exited with error"
        return 1
    }
}

gpg_encrypt_file() {
    if [[ ! -f "$1" ]] && [[ ! -L "$1" ]]; then
        echo "input file ${1} does not exist"
        return 1
    fi

    local input_file_path="$1"
    local output_file_path="$2"
    local output_filename
    output_filename=$(basename "$output_file_path")
    local tmp_output_file_path="${tmp_path}/${output_filename}"
    local input_file_existing_equal=false

    # if the file to replace already exists, perform a diff to check for changes
    if [[ -f "$output_file_path" ]]; then
        tmp_output_file_path_current="$tmp_output_file_path".current
        gpg --quiet --no-verbose --local-user "$gpg_encryption_subkey" --armor --decrypt --yes --output "$tmp_output_file_path_current" "$output_file_path" >/dev/null || {
            echo "failed to decrypt file ${output_file_path} to ${tmp_output_file_path_current}"
            return 1
        }

        if (cmp -s "$tmp_output_file_path_current" "$input_file_path"); then
            input_file_existing_equal=true
        else
            diff_files "$tmp_output_file_path_current" "$input_file_path"
        fi
    fi

    if [[ $input_file_existing_equal == true ]]; then
        printf "%s <-> %s are equal. skipping encryption.\n" "$input_file_path" "$output_file_path"
    else
        gpg --quiet --no-verbose --local-user "$gpg_encryption_subkey" --recipient "$gpg_encryption_subkey" --armor --sign --yes --output "$tmp_output_file_path" --encrypt "$input_file_path" >/dev/null || {
            echo "failed to encrypt file ${input_file_path} to ${tmp_output_file_path}"
            return 1
        }

        cp -f "$tmp_output_file_path" "$output_file_path" || {
            echo "failed to copy '${tmp_output_file_path}' to '${output_file_path}'"
            return 1
        }

        printf "%s -> %s\n" "$input_file_path" "$output_file_path"
    fi
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

if [[ -n ${DOTFILES+x} ]] && [[ "$base_path" != "$DOTFILES" ]]; then
    echo "Changing directory to '${DOTFILES}'"
    cd "$DOTFILES"
    update_paths
fi

if [[ ! $(gpg --list-keys "$gpg_primary_key") ]]; then
    gpg --import "$data_path"/gpg/2B7340DB13C85766.asc
fi

mkdir -p "$tmp_path"

declare -a encrypt_data_paths_tuples=(
    "${HOME}/.config/corectrl/profiles/_global_.ccpro ${data_path}/corectrl/${current_hostname}__global_.ccpro.asc.gpg"
    "${HOME}/.config/corectrl/profiles/codium.ccpro ${data_path}/corectrl/${current_hostname}_codium.ccpro.asc.gpg"
    "${HOME}/.config/corectrl/profiles/gyroflow.ccpro ${data_path}/corectrl/${current_hostname}_gyroflow.ccpro.asc.gpg"
    "${HOME}/.config/corectrl/profiles/steam.sh.ccpro ${data_path}/corectrl/${current_hostname}_steam.sh.ccpro.asc.gpg"
    "${HOME}/.config/gallery-dl/config.json ${data_path}/gallery-dl/config.json.asc.gpg"
    "${HOME}/.config/gtk-3.0/bookmarks ${data_path}/gtk/bookmarks.asc.gpg"
    "${HOME}/.config/khal/config ${data_path}/khal/config.asc.gpg"
    "${HOME}/.config/mimeapps.list ${data_path}/xdg/mimeapps.list.asc.gpg"
    "${HOME}/.config/tidal-hifi/config.json ${data_path}/tidal-hifi/config.json.asc.gpg"
    "${HOME}/.config/vdirsyncer/config ${data_path}/vdirsyncer/config.asc.gpg"
    "${HOME}/.config/waybar-crypto/config.ini ${data_path}/waybar/waybar-crypto/config.ini.asc.gpg"
    "${HOME}/.ssh/config ${data_path}/ssh/config.asc.gpg"
    "${HOME}/.config/cura/5.7/cura.cfg ${data_path}/cura/cura.cfg.asc.gpg"
    "${HOME}/.config/PrusaSlicer/PrusaSlicer.ini ${data_path}/prusaslicer/PrusaSlicer.ini.asc.gpg"
    "${pkglist_system_path} ${data_path}/pkgs/${current_hostname}.txt.asc.gpg"
    "$data_path/pkgs/remove.txt ${data_path}/pkgs/remove.txt.asc.gpg"
)

for encrypt_data_paths_tuple in "${encrypt_data_paths_tuples[@]}"; do
    read -ra encrypt_data_paths <<<"$encrypt_data_paths_tuple"

    if [[ -f "${encrypt_data_paths[0]}" ]]; then
        echo "${encrypt_data_paths_tuple}"
        gpg_encrypt_file "${encrypt_data_paths[0]}" "${encrypt_data_paths[1]}"
    else
        echo "No file found for ${encrypt_data_paths[0]}."
    fi
done
