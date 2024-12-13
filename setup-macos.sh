#!/usr/bin/env bash

gpg_primary_key=0x2B7340DB13C85766
gpg_encryption_subkey=0x79C70BBE4865D828

base_path=$PWD
data_path="$base_path"/data

declare -a brew_pkgs=(
    bat
    gnupg
    go
    helix
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

git submodule update --init --remote --progress omz/.oh-my-zsh/themes/powerlevel10k || {
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
    ~/.cargo
    ~/.config
    ~/.continue
    ~/.local/bin
    ~/.ssh
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
    ssh
    stow
    zsh
)

echo "Stowing setup configs"
for stow_dir in "${stow_dirs_setup[@]}"; do
    stow_config "$stow_dir"
done

rsync --progress -ruacv -- macos/* "$HOME"/ || {
    echo "failed to rsync macos config"
    return 1
}

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
