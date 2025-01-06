#!/usr/bin/env bash

gpg_primary_key=0x2B7340DB13C85766
gpg_encryption_subkey=0x79C70BBE4865D828

base_path=$PWD
data_path="$base_path"/data
git_submodule_path="$base_path"/.git_submodules

exit_setup() {
    rv=$?
    printf "\n\nExiting setup...\n"
    exit $rv
}

set -euo pipefail
trap 'exit_setup' ERR INT
symlink() {
    if [[ -e "${2}" ]]; then
        if [[ ! -L "${2}" ]]; then
            echo "${2} already exists and is an irregular type. Check manually whether this is safe to replace with ${1}."
            return 1
        fi

        echo "Removing existing symlink at ${2}"
        rmrf "${2}" || {
            echo "failed to remove old symlink: ${2}"
            return 1
        }
    fi

    # Stow only supports relative symlinks
    ln -s "${1}" "${2}" || {
        echo "failed to symlink: ${1} to ${2}"
        return 1
    }
}

rmrf() {
    rm -rf "${1}" || {
        echo "failed to recursively remove ${1}"
        return 1
    }
}

declare -a brew_pkgs=(
    bat
    font-hack-nerd-font
    gnupg
    go
    helix
    mpv
    neovim
    node
    npm
    pinentry-mac
    python
    ruby
    rust
    stow
    theseal/ssh-askpass/ssh-askpass
    wget
    ykman
    yubikey-personalization
)

brew update || {
    echo "failed to update homebrew"
}

brew install "${brew_pkgs[@]}" || {
    echo "failed to install brew packages"
}

git submodule update --init --recursive --remote --progress || {
    echo "failed to update git submodules"
    exit 1
}

git submodule foreach --recursive git clean -xfd || {
    echo "failed to clean git submodules"
    exit 1
}

git submodule foreach --recursive git reset --hard || {
    echo "failed to reset git submodules"
    exit 1
}

echo "Setting up GPG/SSH"
gpg --list-keys >/dev/null

declare -a mk_dirs=(
    ~/.cargo
    ~/.config
    ~/.continue
    ~/.local/bin
    ~/.local/share
    ~/.ssh
    ~/Library/KeyBindings
    ~/Library/LaunchAgents
)

for mk_dir in "${mk_dirs[@]}"; do
    mkdir -p "${mk_dir}"
done

declare -a conflict_paths=(
    ~/.bashrc
    ~/.continue/config.json
    ~/.gnupg/common.conf
    ~/.zshenv
    ~/.zshrc
)

rm_if_not_stowed() {
    if [[ -L "${1}" ]]; then
        local symlink_path
        symlink_path=$(readlink -f "${1}")
        if [[ $symlink_path == *"${base_path}"* ]]; then
            return 0
        fi
    fi

    rm -rfv "${1}"
}

echo "Checking for files/directories that will conflict with stow"
for conflict_path in "${conflict_paths[@]}"; do
    rm_if_not_stowed "${conflict_path}"
done

echo "Appending custom pinentry script to gpg-agent.conf"
# GNUPG is ridiculous and only allows env-vars in some of the options here, so we have to do this the convoluted way with a line append
cp -v "$data_path"/gpg/gpg-agent.conf "$base_path"/gpg/.gnupg/gpg-agent.conf || {
    echo "failed to copy gpg-agent.conf from data dir"
    exit 1
}
echo "pinentry-program $HOME/.local/bin/pinentry-auto" | tee -a "$HOME"/.gnupg/gpg-agent.conf

# Fix for spacing breaking the space delimited tuples
mv "${git_submodule_path}"/catppuccin-bat/themes/Catppuccin\ Mocha.tmTheme "${git_submodule_path}"/catppuccin-bat/themes/Catppuccin-Mocha.tmTheme || {
    echo "failed to move catppuccin-bat theme"
    exit 1
}

declare -a symlink_paths_tuples=(
    "${git_submodule_path}/alacritty-theme/themes ${base_path}/alacritty/.config/alacritty/themes"
    "${git_submodule_path}/catppuccin-bat/themes/Catppuccin-Mocha.tmTheme ${base_path}/bat/.config/bat/themes/Catppuccin-Mocha.tmTheme"
    "${git_submodule_path}/catppuccin-helix/themes/default/catppuccin_mocha.toml ${base_path}/helix/.config/helix/themes/catppuccin_mocha.toml"
)
for symlink_paths_tuple in "${symlink_paths_tuples[@]}"; do
    read -ra symlink_paths <<<"$symlink_paths_tuple"
    symlink "${symlink_paths[0]}" "${symlink_paths[1]}"
done

stow_config() {
    stow -v "$1" || {
        echo "Failed to stow ${1} config"
        exit 1
    }
}

declare -a stow_dirs_setup=(
    bash
    git
    gpg
    macos
    ssh
    stow
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

# If our primary GPG key is not yet imported, import it
if [[ ! $(gpg --list-keys "$gpg_primary_key") ]]; then
    gpg --import "$data_path"/gpg/2B7340DB13C85766.asc || {
        echo "failed to import GPG pubkey"
        exit 1
    }

    gpg --tofu-policy good "$gpg_primary_key" || {
        echo "failed to set gpg tofu policy"
        exit 1
    }
fi

echo "Decrypting data"
declare -a decrypt_data_paths_tuples=(
    "${data_path}/ssh/config.asc.gpg ${base_path}/ssh/.ssh/config"
)

for decrypt_data_paths_tuple in "${decrypt_data_paths_tuples[@]}"; do
    read -ra decrypt_data_paths <<<"$decrypt_data_paths_tuple"
    if [[ -f "${decrypt_data_paths[0]}" ]]; then
        gpg --quiet --no-verbose --local-user "${gpg_encryption_subkey}" --armor --decrypt --yes --output "${decrypt_data_paths[1]}" "${decrypt_data_paths[0]}"  >/dev/null || {
            echo "failed to decrypt file ${decrypt_data_paths[0]} to ${decrypt_data_paths[1]}"
            exit 1
        }
    fi
done

declare -a stow_dirs_general=(
    alacritty
    bat
    continue
    helix
    nvim
    rust
)

echo "Stowing general configs"
for stow_dir in "${stow_dirs_general[@]}"; do
    stow_config "$stow_dir"
done
