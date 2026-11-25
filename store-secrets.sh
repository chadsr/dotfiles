#!/usr/bin/env bash

gpg_primary_key=0x2B7340DB13C85766
gpg_encryption_subkey=0x79C70BBE4865D828

pkglist_system_path=/etc/pkglist.txt

current_hostname=$(hostname)

tmp_path=/tmp/secrets-"$current_hostname"
declare -a diff_command=(vimdiff -d)

exit_script() {
  rv=$?
  printf "\n\nExiting...\n"
  exit "$rv"
}

set -euo pipefail
trap 'exit_script' ERR INT

source "$(dirname "${BASH_SOURCE[0]}")/setup-lib.sh" || {
  echo "failed to source setup-lib.sh"
  exit 1
}

trap 'cleanup_tmp_dir' EXIT

update_paths() {
  base_path=$PWD
  data_path="$base_path"/data
}

update_paths

help() {
  printf "Stores configuration secrets to \"%s\".\n" "$data_path"
}

cd_dotfiles
update_paths

import_gpg_pubkey

init_tmp_dir

declare -a encrypt_data_paths_tuples=(
  "${HOME}/.android/keystores/keystore ${data_path}/android/keystores/keystore.asc.gpg"
  "${HOME}/.config/ai-usagebar/config.toml ${data_path}/waybar/ai-usagebar/config.toml.asc.gpg"
  "${HOME}/.config/cura/5.11/cura.cfg ${data_path}/cura/cura.cfg.asc.gpg"
  "${HOME}/.config/gallery-dl/config.json ${data_path}/gallery-dl/config.json.asc.gpg"
  "${HOME}/.config/gtk-3.0/bookmarks ${data_path}/gtk/bookmarks.asc.gpg"
  "${HOME}/.config/khal/config ${data_path}/khal/config.asc.gpg"
  "${HOME}/.config/mimeapps.list ${data_path}/xdg/mimeapps.list.asc.gpg"
  "${HOME}/.config/Nextcloud/nextcloud.cfg ${data_path}/nextcloud/nextcloud.cfg.asc.gpg"
  "${HOME}/.config/PrusaSlicer/PrusaSlicer.ini ${data_path}/prusaslicer/PrusaSlicer.ini.asc.gpg"
  "${HOME}/.config/qBittorrent/categories.json ${data_path}/qbittorrent/categories.json.asc"
  "${HOME}/.config/qBittorrent/qBittorrent.conf ${data_path}/qbittorrent/qBittorrent.conf.asc"
  "${HOME}/.config/tidal-hifi/config.json ${data_path}/tidal-hifi/config.json.asc.gpg"
  "${HOME}/.config/vdirsyncer/config ${data_path}/vdirsyncer/config.asc.gpg"
  "${HOME}/.config/waybar-crypto/config.ini ${data_path}/waybar/waybar-crypto/config.ini.asc.gpg"
  "${HOME}/.docker/mcp/config.yaml ${data_path}/docker/mcp/config.yaml.asc.gpg"
  "${HOME}/.local/state/herdr/client/endpoints.json ${data_path}/herdr/${current_hostname}/endpoints.json.asc.gpg"
  "${HOME}/.radicle/keys/radicle ${data_path}/radicle/keys/radicle.asc.gpg"
  "${HOME}/.ssh/config ${data_path}/ssh/config.asc.gpg"
  "${pkglist_system_path} ${data_path}/pkgs/${current_hostname}.txt.asc.gpg"
  "$base_path/system/${current_hostname}/boot/loader/entries/arch-cachyos.conf ${data_path}/system/${current_hostname}/boot/loader/entries/arch-cachyos.asc.conf"
  "$base_path/system/${current_hostname}/boot/loader/entries/arch-zen.conf ${data_path}/system/${current_hostname}/boot/loader/entries/arch-zen.asc.conf"
  "$data_path/pkgs/remove.txt ${data_path}/pkgs/remove.txt.asc.gpg"
)

for encrypt_data_paths_tuple in "${encrypt_data_paths_tuples[@]}"; do
  read -ra encrypt_data_paths <<<"$encrypt_data_paths_tuple"

  if [[ -f "${encrypt_data_paths[0]}" ]]; then
    echo "$encrypt_data_paths_tuple"
    gpg_encrypt_file "${encrypt_data_paths[0]}" "${encrypt_data_paths[1]}"
  else
    echo "No file found for ${encrypt_data_paths[0]}."
  fi
done

# Not secrets, but included in this script anyway
declare -a docker_mcp_profiles=(
  dev-tools
)

for docker_mcp_profile in "${docker_mcp_profiles[@]}"; do
  docker mcp profile export "$docker_mcp_profile" "${base_path}/docker/.docker/mcp/profiles/${docker_mcp_profile}.yaml" || {
    echo "failed to export mcp profile ${docker_mcp_profile}"
    exit 1
  }
done
