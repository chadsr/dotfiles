#!/usr/bin/env bash

gpg_primary_key=0x2B7340DB13C85766
gpg_encryption_subkey=0x79C70BBE4865D828

base_path=$PWD
data_path="$base_path"/data
git_submodule_path="$base_path"/.git_submodules

package_manager=/opt/homebrew/bin/brew
diff_command="nvim -d"
tmp_path=/tmp/setup-"${HOSTNAME}"

set -euo pipefail
trap 'exit_setup' ERR INT

source "$(dirname "${BASH_SOURCE[0]}")/setup-lib.sh" || {
  echo "failed to source setup-lib.sh"
  exit 1
}

mkdir -p "$tmp_path"

prompt_exit "This script will remove/change existing system settings."

declare -a brew_pkgs=(
  bat
  direnv
  docker
  dua-cli
  fnm
  font-hack-nerd-font
  ghostty
  gnupg
  go
  helix
  mpv
  neovim
  node
  npm
  pinentry-mac
  python
  rust
  starship
  stats
  stow
  theseal/ssh-askpass/ssh-askpass
  wget
  ykman
  yubikey-personalization
  zsh-autocomplete
  zsh-autosuggestions
  zsh-completions
  zsh-syntax-highlighting
)

"$package_manager" update || {
  echo "failed to update homebrew"
  exit 1
}

install_packages "${brew_pkgs[@]}"

update_submodules

echo "Setting up GPG/SSH"
gpg --list-keys >/dev/null

declare -a mk_dirs=(
  ~/.cargo/
  ~/.config/
  ~/.continue/
  ~/.gnupg-forward/
  ~/.local/bin/
  ~/.local/share/
  ~/.ssh/
  ~/Library/KeyBindings/
  ~/Library/LaunchAgents/
)

for mk_dir in "${mk_dirs[@]}"; do
  mkdir -p "${mk_dir}"
done

# gpg requires strict perms when ~/.gnupg-forward is used as GNUPGHOME
chmod 700 ~/.gnupg-forward

declare -a conflict_paths=(
  ~/.bashrc
  ~/.continue/config.json
  ~/.gnupg/common.conf
  ~/.zshenv
  ~/.zlogout
  ~/.zshrc
)

echo "Checking for files/directories that will conflict with stow"
for conflict_path in "${conflict_paths[@]}"; do
  rm_if_not_stowed "${conflict_path}"
done

echo "Setting up stow"
stow -t ~/ stow || {
  echo "failed to setup stow"
  exit 1
}

echo "Appending custom pinentry script to gpg-agent.conf"
setup_pinentry

declare -a stow_dirs_setup=(
  bash
  git
  gpg
  macos
  ssh
  zsh
)

echo "Stowing setup configs"
for stow_dir in "${stow_dirs_setup[@]}"; do
  stow_config "$stow_dir"
done

declare -a launch_agents=(
  "$HOME"/Library/LaunchAgents/gnupg.gpg-agent.plist
  "$HOME"/Library/LaunchAgents/gnupg.gpg-agent-symlink.plist
)

for launch_agent_dir in "${launch_agents[@]}"; do
  launchctl unload "$launch_agent_dir"
  launchctl load "$launch_agent_dir" || {
    echo "failed to load $launch_agent_dir"
    exit 1
  }
  echo "Loaded $launch_agent_dir"
done

gpg-connect-agent reloadagent /bye || {
  echo "failed to reload gpg-agent"
  exit 1
}

import_gpg_pubkey

echo "Decrypting data"
declare -a decrypt_data_paths_tuples=(
  "${data_path}/ssh/config.asc.gpg ${base_path}/ssh/.ssh/config"
  "${data_path}/android/keystores/keystore-rossch.asc.gpg ${base_path}/android/.android/keystores/keystore-rossch"
)

for decrypt_data_paths_tuple in "${decrypt_data_paths_tuples[@]}"; do
  read -ra decrypt_data_paths <<<"$decrypt_data_paths_tuple"

  if [[ -f "${decrypt_data_paths[0]}" ]]; then
    gpg_decrypt_file "${decrypt_data_paths[0]}" "${decrypt_data_paths[1]}"
  fi
done

fix_catppuccin_bat_theme

declare -a symlink_paths_tuples=(
  "${git_submodule_path}/catppuccin-bat/themes/Catppuccin-Mocha.tmTheme ${base_path}/bat/.config/bat/themes/Catppuccin-Mocha.tmTheme"
  "${git_submodule_path}/catppuccin-helix/themes/default/catppuccin_mocha.toml ${base_path}/helix/.config/helix/themes/catppuccin_mocha.toml"
)
for symlink_paths_tuple in "${symlink_paths_tuples[@]}"; do
  read -ra symlink_paths <<<"$symlink_paths_tuple"
  symlink "${symlink_paths[0]}" "${symlink_paths[1]}"
done

declare -a stow_dirs_general=(
  android
  bat
  continue
  freetube
  ghostty
  helix
  herdr
  mise
  nvim
  opencode
  openspec
  rust
  skillshare
  starship
)

echo "Stowing general configs"
for stow_dir in "${stow_dirs_general[@]}"; do
  stow_config "$stow_dir"
done

defaults write com.apple.finder AppleShowAllFiles -boolean true || {
  echo "failed to enable hidden files in Finder"
  exit 1
}

defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true || {
  echo "failed to disable network DS_Store"
  exit 1
}

defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true || {
  echo "failed to disable USB DS_Store"
  exit 1
}

declare -a ollama_models=(
  qwen2.5-coder:1.5b
  nomic-embed-text:latest
)

pull_ollama_models "${ollama_models[@]}"
