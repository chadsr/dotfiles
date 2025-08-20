#!/usr/bin/env bash

gpg_primary_key=0x2B7340DB13C85766
gpg_encryption_subkey=0x79C70BBE4865D828

laptop_hostname="thinky"
desktop_hostname="shifty"
current_hostname=${HOSTNAME}

tmp_path=/tmp/setup-"$current_hostname"

package_manager=/usr/bin/yay
pkglist_system_path=/etc/pkglist.txt
diff_command="nvim -d"

# bare minimum packages needed by this script in order to bootstrap
declare -a script_pkgs=(
    ccid
    gnupg
    neovim
    pass
    pcsclite
    stow
    systemd-ukify
)

exit_setup() {
    rv=$?
    printf "\n\nExiting setup...\n"
    exit $rv
}

set -euo pipefail
trap 'exit_setup' ERR INT

script_name=$(basename "$0")

help() {
    printf "Sets up system packages and configurations.\n\nUsage: %s <%s|%s>\n" "$script_name" "$laptop_hostname" "$desktop_hostname"
}

prompt_exit() {
    read -rp "$1 Continue or Abort? (y/N)" answer
    case ${answer:0:1} in
    y | Y)
        return 0
        ;;
    *)
        exit_setup 0
        ;;
    esac
}

update_paths() {
    base_path=$PWD
    data_path="$base_path"/data
    system_config_path="$base_path"/system
    git_submodule_path="$base_path"/.git_submodules
}

update_paths

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

prompt_exit "This script will remove/change existing system settings."

if [[ -n ${DOTFILES+x} ]] && [[ "$base_path" != "$DOTFILES" ]]; then
    echo "Changing directory to '${DOTFILES}'"
    cd "$DOTFILES"
    update_paths
fi

install_packages() {
    "$package_manager" -S --noconfirm --needed --noredownload -- "${@}" || {
        echo "failed to install:"
        echo "${@}"
        return 1
    }
}

remove_package() {
    if "$package_manager" -Qi "$1" >/dev/null; then
        "$package_manager" -R --noconfirm -- "$1" >/dev/null || {
            :
        }
    fi
}

rmrf() {
    rm -rf "${1}" || {
        echo "failed to recursively remove ${1}"
        return 1
    }
}

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
    ln -rs "${1}" "${2}" || {
        echo "failed to symlink: ${1} to ${2}"
        return 1
    }
}

rsync_system_config() {
    local system_config_full_path="$system_config_path"/"${1}"

    if [[ ! -d "$system_config_full_path" ]]; then
        echo "The provided path '${system_config_full_path}' does not exist!"
        return 1
    fi

    sudo rsync --chown=root:root --open-noatime --exclude='.gitkeep' --progress -ruacv -- "${system_config_full_path}"/* / || {
        echo "failed to rsync system config from ${system_config_full_path} to root filesystem"
        return 1
    }
}

systemd_enable_start() {
    local unit_path="${1}"
    local unit_name
    unit_name=$(basename "${1}")

    if ! (systemctl -q is-enabled -- "${unit_name}"); then
        echo "Enabling Systemd Unit ${unit_name}"
        sudo systemctl enable -- "${unit_path}" || {
            echo "failed to enable systemd unit ${unit_name}"
            return 1
        }
    fi
    if ! (systemctl -q is-active "${unit_name}"); then
        echo "Starting Systemd Unit ${unit_name}"
        sudo systemctl start -- "${unit_name}" || {
            echo "failed to start systemd unit ${unit_name}"
            return 1
        }
    fi
}

systemd_user_enable_start() {
    local unit_path="${1}"
    local unit_name
    unit_name=$(basename "${1}")

    if ! (systemctl --user -q is-enabled -- "${unit_name}"); then
        echo "Enabling Systemd User Unit ${unit_name}"
        systemctl --user enable -- "${unit_path}" || {
            echo "failed to enable systemd user unit ${unit_name}"
            return 1
        }
    fi
    if ! (systemctl --user -q is-active -- "${unit_name}"); then
        echo "Starting Systemd User Unit ${unit_name}"
        systemctl --user start -- "${unit_name}" || {
            echo "failed to start systemd user unit ${unit_name}"
            return 1
        }
    fi
}

gpg_ssh_agent() {
    systemctl --user restart gpg-agent
    unset SSH_AGENT_PID
    if [ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]; then
        SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
        export SSH_AUTH_SOCK
    fi
    GPG_TTY="${TTY:-"$(tty)"}"
    export GPG_TTY
    gpg-connect-agent updatestartuptty /bye >/dev/null
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

    if (cmp -s "$1" "$2"); then
        # If they are identical, then return
        return 0
    else
        ${diff_command} "$1" "$2" || {
            echo "${diff_command} on ${1} <-> ${2}' exited with error"
            return 1
        }
    fi
}

# gpg is used directly throughout this setup process
# to handle the non-deterministic nature of gpg encryption, checks/diffs are performed to prevent unwanted changes going un-noticed
gpg_decrypt_file() {
    if [[ ! -f "$1" ]] && [[ ! -L "$1" ]]; then
        echo "input file ${1} does not exist"
        return 1
    fi

    local input_file_path="${1}"
    local output_file_path="${2}"
    local output_filename
    output_filename=$(basename "${output_file_path}")
    local tmp_output_file_path="${tmp_path}/${output_filename}"

    echo "Decrypting ${input_file_path} to ${tmp_output_file_path}"

    gpg --quiet --no-verbose --local-user "${gpg_encryption_subkey}" --armor --decrypt --yes --output "${tmp_output_file_path}" "${input_file_path}" >/dev/null || {
        echo "failed to decrypt file ${input_file_path} to ${tmp_output_file_path}"
        return 1
    }

    # if the file to replace already exists, perform a diff to check for changes
    if [[ -f "$output_file_path" ]]; then
        diff_files "$output_file_path" "$tmp_output_file_path"
    fi

    cp -f "$tmp_output_file_path" "$output_file_path" || {
        echo "failed to copy '${tmp_output_file_path}' to '${output_file_path}'"
        return 1
    }
}

line_exists() {
    case $(
        grep -Fxq "${1}" "${2}" >/dev/null
        echo $?
    ) in
    0)
        # Found
        return 0
        ;;
    1)
        # Not found
        return 1
        ;;
    *)
        exit 1
        ;;
    esac
}

string_exists() {
    case $(
        grep -Fq "${1}" "${2}" >/dev/null
        echo $?
    ) in
    0)
        # Found
        return 0
        ;;
    1)
        # Not found
        return 1
        ;;
    *)
        exit 1
        ;;
    esac
}

add_group_user() {
    sudo groupadd "${1}" || {
        :
    }

    sudo usermod -a -G "${1}" "$(whoami)" || {
        echo "Failed to add $(whoami) to group ${1}"
        exit 1
    }
}

set_default_kernel() {
    local efi_loader_conf_path=/boot/loader/loader.conf
    local kernel_suffix="${1}".conf

    case $(
        sudo grep -G -- '^default.*'"${kernel_suffix}"'$' "${efi_loader_conf_path}" >/dev/null
        echo $?
    ) in
    0)
        echo "Linux ${kernel_suffix} kernel already default"
        ;;
    1)
        read -p "Make Linux ${kernel_suffix} kernel default (y/N)?" -n 1 -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            case $(
                sudo grep -G -- '^default.*\*$' "${efi_loader_conf_path}" >/dev/null
                echo $?
            ) in
            0) ;;
            1)
                echo "Expected default kernel to be a wildcard (ending with *) in ${efi_loader_conf_path}"
                exit 1
                ;;
            *)
                echo "Failed to check for wildcard suffix in ${efi_loader_conf_path}"
                exit 1
                ;;
            esac
            sudo sed -i '/^default/s/$/'"${kernel_suffix}"'/' "${efi_loader_conf_path}"
        fi
        echo "Linux ${kernel_suffix} kernel set to default"
        ;;
    *)
        echo "Failed to check ${efi_loader_conf_path} for ${kernel_suffix} kernel"
        exit 1
        ;;
    esac
}

rm_if_not_stowed() {
    if [[ -L "${1}" ]]; then
        local symlink_path
        symlink_path=$(readlink -f "${1}")
        if [[ $symlink_path == *"${base_path}"* ]]; then
            return 0
        fi
    fi

    rm -rfv "${1}" || {
        echo "failed to remove conflict path ${1}"
        return 1
    }
}

stow_config() {
    stow -v "$1" || {
        echo "Failed to stow ${1} config"
        exit 1
    }
}

mkdir -p "$tmp_path"

echo "Updating package databases & packages"
"$package_manager" -Syu || {
    echo "failed to update package databases"
    exit 1
}

# Install the bare minimum packages for this script to work
install_packages "${script_pkgs[@]}"

echo "Setting up GPG/SSH"
gpg --list-keys >/dev/null
systemd_enable_start /usr/lib/systemd/system/pcscd.socket

echo "Removing broken symlinks in ${HOME}/.config"
find ~/.config/ -xtype l -print -delete || {
    echo "Failed to remove broken symlinks"
    exit 1
}

declare -a old_files=(
    /etc/environment.d/qt5.conf
    /etc/environment.d/java.conf
)
echo "Checking for old files to remove"
for old_file in "${old_files[@]}"; do
    sudo rm -vf "$old_file" || {
        echo "failed to remove ${old_file}"
        exit 1
    }
done

echo "Setting up stow"
stow -t ~/ stow || {
    echo "failed to setup stow"
    exit 1
}

echo "Setting up user directory configs"

# Parent dirs that should not be symlinks from stow-ing
declare -a mk_dirs=(
    ~/.cargo/
    ~/.config/bat/themes/
    ~/.config/corectrl/profiles/
    ~/.config/environment.d/
    ~/.config/figma-linux/
    ~/.config/khal/
    ~/.config/Kvantum/
    ~/.config/Logseq/
    ~/.config/nvim/
    ~/.config/pulse/
    ~/.config/pulseaudio-ctl/
    ~/.config/systemd/user/
    ~/.config/Thunar/
    ~/.config/tidal-hifi/
    ~/.config/VSCodium/User/globalStorage/
    ~/.config/xfce4/xfconf/xfce-perchannel-xml/
    ~/.continue/
    ~/.icons/
    ~/.local/bin/
    ~/.local/share/applications/
    ~/.local/share/fonts/OTF/
    ~/.local/share/fonts/TTF/
    ~/.logseq/config/
    ~/.nvm/alias/
    ~/.radicle/keys/
    ~/.ssh/
    ~/.themes/
    ~/.vscode-oss/
    ~/Pictures/Backgrounds/
    ~/Pictures/Screenshots/
)
for mk_dir in "${mk_dirs[@]}"; do
    mkdir -p "${mk_dir}"
done

declare -a conflict_paths=(
    ~/.bash_env
    ~/.bash_login
    ~/.bash_logout
    ~/.bash_profile
    ~/.bashrc
    ~/.config/gtk-3.0
    ~/.config/gtk-3.0
    ~/.config/gtk-4.0
    ~/.config/mimeapps.list
    ~/.config/Thunar/uca.xml
    ~/.config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml
    ~/.gnupg/common.conf
    ~/.gtkrc-2.0
    ~/.vscode-oss/argv.json
    ~/.zlogin
    ~/.zlogout
    ~/.zprofile
    ~/.zshenv
    ~/.zshrc
)
echo "Checking for files/directories that will conflict with stow"
for conflict_path in "${conflict_paths[@]}"; do
    rm_if_not_stowed "${conflict_path}"
done

if ! [ -e "$HOME/.config/sunsetr/geo.toml" ]; then
    touch "$HOME/.config/sunsetr/geo.toml" || {
        echo "failed to create sunsetr geo.toml"
        exit 1
    }
fi

echo "Appending custom pinentry script to gpg-agent.conf"
# GNUPG is ridiculous and only allows env-vars in some of the options here, so we have to do this the convoluted way with a line append
cp -v "$data_path"/gpg/gpg-agent.conf "$base_path"/gpg/.gnupg/gpg-agent.conf || {
    echo "failed to copy gpg-agent.conf from data dir"
    exit 1
}
echo "pinentry-program $HOME/.local/bin/pinentry-auto" | tee -a "$base_path"/gpg/.gnupg/gpg-agent.conf

declare -a stow_dirs_setup=(
    bash
    git
    gpg
    rust
    ssh
    yay
    zsh
)

echo "Stowing setup configs"
for stow_dir in "${stow_dirs_setup[@]}"; do
    stow_config "$stow_dir"
done

# shellcheck disable=SC1090
source ~/.bashrc || {
    echo "failed to source .bashrc"
    exit 1
}

systemd_user_enable_start "$base_path"/gpg/.config/systemd/user/gnupghome.service
systemd_user_enable_start "$base_path"/gpg/.config/systemd/user/ssh-auth-sock.service
systemd_user_enable_start /usr/lib/systemd/user/gpg-agent.service

gpg_ssh_agent

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

pass init "$gpg_primary_key" || {
    echo "failed to init pass"
    exit 1
}

pkglist_remove_path="$data_path"/pkgs/remove.txt

echo "Decrypting data"
declare -a decrypt_data_paths_tuples=(
    "${data_path}/corectrl/${current_hostname}__global_.ccpro.asc.gpg ${base_path}/corectrl/.config/corectrl/profiles/_global_.ccpro"
    "${data_path}/corectrl/${current_hostname}_codium.ccpro.asc.gpg ${base_path}/corectrl/.config/corectrl/profiles/codium.ccpro"
    "${data_path}/corectrl/${current_hostname}_gamemoded.ccpro.asc.gpg ${base_path}/corectrl/.config/corectrl/profiles/gamemoded.ccpro"
    "${data_path}/corectrl/${current_hostname}_gyroflow.ccpro.asc.gpg ${base_path}/corectrl/.config/corectrl/profiles/gyroflow.ccpro"
    "${data_path}/cura/cura.cfg.asc.gpg ${base_path}/cura/.config/cura/5.7/cura.cfg"
    "${data_path}/gallery-dl/config.json.asc.gpg ${base_path}/gallery-dl/.config/gallery-dl/config.json"
    "${data_path}/gtk/bookmarks.asc.gpg ${base_path}/gtk/.config/gtk-3.0/bookmarks"
    "${data_path}/khal/config.asc.gpg ${base_path}/khal/.config/khal/config"
    "${data_path}/pkgs/remove.txt.asc.gpg ${pkglist_remove_path}"
    "${data_path}/prusaslicer/PrusaSlicer.ini.asc.gpg ${base_path}/prusaslicer/.config/PrusaSlicer/PrusaSlicer.ini"
    "${data_path}/radicle/keys/radicle.asc.gpg ${base_path}/radicle/.radicle/keys/radicle"
    "${data_path}/ssh/config.asc.gpg ${base_path}/ssh/.ssh/config"
    "${data_path}/system/${current_hostname}/boot/loader/entries/arch-zen.asc.conf ${base_path}/system/${current_hostname}/boot/loader/entries/arch-zen.conf"
    "${data_path}/tidal-hifi/config.json.asc.gpg ${base_path}/tidal-hifi/.config/tidal-hifi/config.json"
    "${data_path}/vdirsyncer/config.asc.gpg ${base_path}/khal/.config/vdirsyncer/config"
    "${data_path}/waybar/waybar-crypto/config.ini.asc.gpg ${base_path}/waybar/.config/waybar-crypto/config.ini"
    "${data_path}/xdg/mimeapps.list.asc.gpg ${base_path}/xdg/.config/mimeapps.list"

)
for decrypt_data_paths_tuple in "${decrypt_data_paths_tuples[@]}"; do
    read -ra decrypt_data_paths <<<"$decrypt_data_paths_tuple"

    if [[ -f "${decrypt_data_paths[0]}" ]]; then
        gpg_decrypt_file "${decrypt_data_paths[0]}" "${decrypt_data_paths[1]}"
    fi
done

# check for packages to be removed
declare -a old_pkgs=()
readarray -t old_pkgs <"$pkglist_remove_path"
echo "Checking for old packages to remove"
for old_pkg in "${old_pkgs[@]}"; do
    remove_package "$old_pkg"
done

# check for packages to be installed
pkglist_path="$data_path"/pkgs/"$current_hostname".txt

# If pkglist_system_path exists, it takes precedence over the backup
if [[ -f $pkglist_system_path ]]; then
    # make sure pkglist_system_path is symlinked to pkglist_path_current
    # if pkglist_path exists and is not symlinked to pkglist_system_path, then remove it
    if [[ -f $pkglist_path ]]; then
        pkglist_link_path=$(readlink -f "$pkglist_path")
        if [[ ! "$pkglist_link_path" == "$pkglist_system_path" ]]; then
            echo "removing ${pkglist_path} because it's not a symlink to ${pkglist_system_path}"
            rm -f "$pkglist_path"
        fi
    fi

    ln -fs "$pkglist_system_path" "$pkglist_path"
else
    # restore from backup
    gpg_decrypt_file "$data_path/pkgs/$current_hostname.txt.asc.gpg" "$pkglist_path"
fi

declare -a pkgs=()
readarray -t pkgs <"$pkglist_path"
install_packages "${pkgs[@]}"

# Add user to groups needed by various packages
declare -a user_groups=(
    audio
    gamemode
    plugdev
    ssh_login
    docker
)
for user_group in "${user_groups[@]}"; do
    echo "Adding user to group ${user_group}"
    add_group_user "$user_group"
done

declare -a systemd_units=(
    /usr/lib/systemd/system/bluetooth.service
    /usr/lib/systemd/system/clamav-freshclam-once.timer
    /usr/lib/systemd/system/input-remapper.service
    /usr/lib/systemd/system/ly.service
    /usr/lib/systemd/system/ollama.service
    /usr/lib/systemd/system/smartd.service
    /usr/lib/systemd/system/swayosd-libinput-backend.service
)
for systemd_unit in "${systemd_units[@]}"; do
    systemd_enable_start "${systemd_unit}"
done

echo "Disabling GNOME Keyring SSH Agent (If it exists)"
sudo systemctl disable gcr-ssh-agent.socket || {
    :
}
sudo systemctl disable gcr-ssh-agent.service || {
    :
}

rustup default stable || {
    echo "failed to setup rust stable toolchain"
    exit 1
}

rustup update || {
    echo "failed to update Rust toolchain"
    exit 1
}

rustup component add clippy rustfmt || {
    echo "failed to install Rust components"
    exit 1
}

sudo update-smart-drivedb

corectrl_rules_path=/etc/polkit-1/rules.d/90-corectrl.rules
if ! sudo test -f "${corectrl_rules_path}"; then
    echo "Setting up polkit for Corectrl"

    envsubst <"$data_path"/corectrl/90-corectrl.rules | sudo tee ${corectrl_rules_path} || {
        echo "Failed to setup polkit for Corectrl"
        exit 1
    }
fi

hyprpm update || {
    echo "failed to update hyprpm"
    exit 1
}

hyprpm add https://github.com/hyprwm/hyprland-plugins || {
    echo "hyprland plugins already installed"
}

hyprpm enable hyprexpo || {
    echo "failed to enable hyprexpo"
    exit 1
}

echo "Copying common system configuration"
rsync_system_config common/

if [[ "$current_hostname" == "$laptop_hostname" ]]; then
    echo "Copying laptop system configuration"
    rsync_system_config "$laptop_hostname"/

    declare -a stow_dirs_laptop=(
        continue-minimal
    )

    echo "Stowing ${laptop_hostname} configs"
    for stow_dir in "${stow_dirs_laptop[@]}"; do
        stow_config "$stow_dir"
    done

    pam_rule="auth      sufficient      pam_fprintd.so max_tries=5 timeout=10"
    read -p "Add PAM fprintd rules? (${pam_rule}) (y/N)?" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo vi /etc/pam.d/sudo
        sudo vi /etc/pam.d/system-local-login
    fi

    declare -a systemd_units_laptop=(
        /usr/lib/systemd/system/tlp.service
        /usr/lib/systemd/system/acpid.service
        /etc/systemd/system/powertop.service
    )
    for systemd_unit in "${systemd_units_laptop[@]}"; do
        systemd_enable_start "${systemd_unit}"
    done

    systemctl --user daemon-reload || {
        echo "failed to daemon-reload"
        exit 1
    }

    declare -a systemd_user_units_laptop=(
        "$base_path"/sway/.config/systemd/user/tablet-rotate.service
    )
    for systemd_user_unit_laptop in "${systemd_user_units_laptop[@]}"; do
        systemd_user_enable_start "${systemd_user_unit_laptop}"
    done

    declare -a ollama_models=(
        deepseek-r1:latest
        qwen2.5-coder:1.5b-base
        nomic-embed-text:latest
        qwen3:14b
    )

    for ollama_model in "${ollama_models[@]}"; do
        ollama pull "${ollama_model}" || {
            echo "failed to install ${ollama_model}"
            exit 1
        }
    done
elif [[ "$current_hostname" == "$desktop_hostname" ]]; then
    # Update amdgpu boot parameter
    # https://wiki.archlinux.org/title/AMDGPU#Boot_parameter
    amdgpu_key="amdgpu.ppfeaturemask"
    cmd_line_file_path=${base_path}/system/${desktop_hostname}/etc/cmdline.d/amdgpu_ppfeaturemask.conf
    amdgpu_boot_parameter=$(printf '%s=0x%x\n' "$amdgpu_key" "$(($(cat /sys/module/amdgpu/parameters/ppfeaturemask) | 0x4000))")
    if sudo test -f "$cmd_line_file_path"; then
        if ! string_exists "$amdgpu_boot_parameter" "$cmd_line_file_path"; then
            echo "Appending boot parameter '$amdgpu_boot_parameter' to $cmd_line_file_path"
            echo " $amdgpu_boot_parameter" | sudo tee "$cmd_line_file_path" >/dev/null
        else
            echo "${amdgpu_key} already exists in ${cmd_line_file_path}. skipping."
        fi
    else
        echo "${cmd_line_file_path} does not exist!"
        exit 1
    fi

    echo "Copying desktop system configuration"
    rsync_system_config "$desktop_hostname"/

    declare -a stow_dirs_desktop=(
        continue
        liquidctl
    )

    echo "Stowing ${desktop_hostname} configs"
    for stow_dir in "${stow_dirs_desktop[@]}"; do
        stow_config "$stow_dir"
    done

    # TODO: Re-enable once decision on kernel builder is made
    # set_default_kernel zen

    declare -a systemd_units_desktop=(
        /usr/lib/systemd/system/coolercontrold.service
        /usr/lib/systemd/system/coolercontrol-liqctld.service
        /usr/lib/systemd/system/power-profiles-daemon.service
    )
    for systemd_unit_desktop in "${systemd_units_desktop[@]}"; do
        systemd_enable_start "${systemd_unit_desktop}"
    done

    systemctl --user daemon-reload || {
        echo "failed to daemon-reload"
        exit 1
    }

    declare -a systemd_user_units_desktop=(
        "$base_path"/liquidctl/.config/systemd/user/liquidctl.service
        "$base_path"/coolercontrol/.config/systemd/user/coolercontrol.service
    )
    for systemd_user_unit_desktop in "${systemd_user_units_desktop[@]}"; do
        systemd_user_enable_start "${systemd_user_unit_desktop}"
    done

    declare -a ollama_models=(
        deepseek-r1:14b
        qwen2.5-coder:latest
        nomic-embed-text:latest
        qwen3:14b
    )

    for ollama_model in "${ollama_models[@]}"; do
        ollama pull "${ollama_model}" || {
            echo "failed to install ${ollama_model}"
            exit 1
        }
    done
fi

# Check if certain submodules get updated, so we don't build them uneccessarily
hackneyed_updated=false
hackneyed_hash_old=$(git -C "$git_submodule_path"/hackneyed-cursor rev-parse --short HEAD)

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

hackneyed_hash_new=$(git -C "$git_submodule_path"/hackneyed-cursor rev-parse --short HEAD)
if [[ "$hackneyed_hash_old" != "$hackneyed_hash_new" ]]; then
    hackneyed_updated=true
    echo "hackneyed-cursor has been updated"
fi

if [[ ! -d ~/.oh-my-zsh ]]; then
    read -p "Do you need to install ohmyzsh? (${git_submodule_path}/ohmyzsh/tools/install.sh) (y/N)?" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -r -p "Press enter once the the installation is finished... [enter]"
        rm -f ~/.zshrc
    fi
fi

echo "Copying themes from git repo to dotfiles locations"

# If Hackneyed Dark build does not exist, then build it
if [[ ! -d "$base_path"/gtk/.icons/hackneyed-dark ]] || [[ $hackneyed_updated == true ]]; then
    echo "Building hackneyed cursor"

    cd "$git_submodule_path"/hackneyed-cursor || {
        echo "failed to cd to hackneyed-cursor"
        exit 1
    }

    make clean distclean || {
        echo "failed to clean hackneyed cursor"
        exit 1
    }

    make -O DARK_THEME=1 dist || {
        echo "failed to make hackneyed cursor"
        exit 1
    }

    rmrf "$base_path"/gtk/.icons/hackneyed-dark
    cp -rv "$git_submodule_path"/hackneyed-cursor/Hackneyed-Dark "$base_path"/gtk/.icons/hackneyed-dark # cp instead of ln because the build dir will get reset by git

    make clean || {
        echo "failed to clean hackneyed make files"
        exit 1
    }
    rm -f ./*.tar.bz2
    cd "$base_path" || {
        echo "failed to cd to ${base_path}"
        exit 1
    }
else
    echo "Skipping hackneyed cursor build"
fi

# Fix for spacing breaking the space delimited tuples
mv "${git_submodule_path}"/catppuccin-bat/themes/Catppuccin\ Mocha.tmTheme "${git_submodule_path}"/catppuccin-bat/themes/Catppuccin-Mocha.tmTheme || {
    echo "failed to move catppuccin-bat theme"
    exit 1
}

declare -a symlink_paths_tuples=(
    "${base_path}/steam/.steam/steam/steam_dev.cfg ${HOME}/.steam/steam/steam_dev.cfg"
    "${git_submodule_path}/alacritty-theme/themes ${base_path}/alacritty/.config/alacritty/themes"
    "${git_submodule_path}/catppuccin-bat/themes/Catppuccin-Mocha.tmTheme ${base_path}/bat/.config/bat/themes/Catppuccin-Mocha.tmTheme"
    "${git_submodule_path}/catppuccin-btop/themes/catppuccin_mocha.theme ${base_path}/btop/.config/btop/themes/catppuccin_mocha.theme"
    "${git_submodule_path}/catppuccin-helix/themes/default/catppuccin_mocha.toml ${base_path}/helix/.config/helix/themes/catppuccin_mocha.toml"
    "${git_submodule_path}/catppuccin-hyprland/themes/mocha.conf ${base_path}/hyprland/.config/hypr/themes/colors.conf"
    "${git_submodule_path}/catppuccin-kvantum/themes/catppuccin-mocha-mauve ${base_path}/qt/.config/Kvantum/catppuccin-mocha-mauve"
    "${git_submodule_path}/catppuccin-rofi/themes/catppuccin-mocha.rasi ${base_path}/rofi/.config/rofi/catppuccin-mocha.rasi"
    "${git_submodule_path}/catppuccin-waybar/themes/mocha.css ${base_path}/waybar/.config/waybar/theme.css"
    "${git_submodule_path}/cryptofont/fonts/cryptofont.ttf ${base_path}/fonts/.local/share/fonts/TTF/cryptofont.ttf"
    "${git_submodule_path}/sweet-theme/assets ${base_path}/gtk/.themes/Sweet/assets"
    "${git_submodule_path}/sweet-theme/gtk-2.0 ${base_path}/gtk/.themes/Sweet/gtk-2.0"
    "${git_submodule_path}/sweet-theme/gtk-3.0 ${base_path}/gtk/.themes/Sweet/gtk-3.0"
    "${git_submodule_path}/sweet-theme/gtk-4.0 ${base_path}/gtk/.themes/Sweet/gtk-4.0"
    "${git_submodule_path}/sweet-theme/index.theme ${base_path}/gtk/.themes/Sweet/index.theme"
)
for symlink_paths_tuple in "${symlink_paths_tuples[@]}"; do
    read -ra symlink_paths <<<"$symlink_paths_tuple"
    symlink "${symlink_paths[0]}" "${symlink_paths[1]}"
done

cp "${git_submodule_path}/catppuccin-rofi/catppuccin-default.rasi" "${base_path}/rofi/.config/rofi/catppuccin-default.rasi" || {
    echo "failed to copy catppuccin-default.rasi"
    exit 1
}

sed -i 's/\/\/ @import "catppuccin-mocha"/@import "catppuccin-mocha"/' "${base_path}/rofi/.config/rofi/catppuccin-default.rasi" || {
    echo "failed to activate rofi catppuccin mocha theme"
    exit 1
}

declare -a stow_dirs_general=(
    alacritty
    bat
    bemenu
    btop
    cava
    chromium
    clipse
    coolercontrol
    corectrl
    cura
    dunst
    electron
    espanso
    fonts
    freetube
    fuzzel
    gallery-dl
    gamemode
    gammastep
    ghostty
    goose
    gtk
    helix
    hyprland
    input-remapper
    java
    kde
    khal
    logseq
    mangohud
    mpv
    nextcloud
    nvim
    nvm
    omz
    pass
    prusaslicer
    qt
    radicle
    ranger
    rofi
    scripts
    solaar
    sway
    swww
    systemd
    thunar
    tidal-hifi
    ulauncher
    vscodium
    waybar
    wlogout
    xdg
    yt-dlp
    yubikey
)

echo "Stowing general configs"
for stow_dir in "${stow_dirs_general[@]}"; do
    echo "Stowing ${stow_dir}"
    stow_config "$stow_dir"
done

bat cache --build || {
    echo "failed to build bat cache"
    exit 1
}

vdirsyncer discover || {
    echo "failed to setup vdirsyncer mailbox"
    exit 1
}

echo "Enabling/Starting Systemd User Units"
systemctl --user daemon-reload || {
    echo "failed to userspace systemd daemon-reload"
    exit 1
}

declare -a systemd_user_targets=(
    "$base_path"/sway/.config/systemd/user/sway-session.target
    "$base_path"/hyprland/.config/systemd/user/hypr-session.target
)
for systemd_user_target in "${systemd_user_targets[@]}"; do
    systemctl --user link "${systemd_user_target}" || {
        echo "failed to enable target ${systemd_user_target}"
        exit 1
    }
done

declare -a systemd_user_units=(
    "$base_path"/corectrl/.config/systemd/user/corectrl.service
    "$base_path"/dunst/.config/systemd/user/dunst-wl.service
    "$base_path"/gtk/.config/systemd/user/xsettingsd.service
    "$base_path"/hyprland/.config/systemd/user/hypr-sunset.service
    "$base_path"/hyprland/.config/systemd/user/hypr-sunsetr.service
    "$base_path"/hyprland/.config/systemd/user/hypridle.service
    "$base_path"/khal/.config/systemd/user/vdirsyncer-sync.service
    "$base_path"/khal/.config/systemd/user/vdirsyncer-sync.timer
    "$base_path"/nextcloud/.config/systemd/user/nextcloud-client.service
    "$base_path"/solaar/.config/systemd/user/solaar.service
    "$base_path"/sway/.config/systemd/user/kanshi.service
    "$base_path"/sway/.config/systemd/user/swayidle.service
    "$base_path"/sway/.config/systemd/user/swayosd.service
    "$base_path"/sway/.config/systemd/user/wlr-sunclock.service
    "$base_path"/swww/.config/systemd/user/swww-daemon.service
    "$base_path"/swww/.config/systemd/user/swww-random.service
    "$base_path"/clipse/.config/systemd/user/clipse.service
    "$base_path"/systemd/.config/systemd/user/enable-linger.service
    "$base_path"/waybar/.config/systemd/user/setup-temps.service
    "$base_path"/waybar/.config/systemd/user/waybar.service
    /usr/lib/systemd/user/batsignal.service
    /usr/lib/systemd/user/gnome-keyring-daemon.socket
    /usr/lib/systemd/user/pipewire-pulse.service
    /usr/lib/systemd/user/pipewire.service
    /usr/lib/systemd/user/wireplumber.service
    /usr/lib/systemd/user/yubikey-touch-detector.socket
    # "$base_path"/espanso/.config/systemd/user/espanso.service
    # "$base_path"/gammastep/.config/systemd/user/gammastep-wayland.service
    # "$base_path"/gammastep/.config/systemd/user/geoclue-agent.service
    # /usr/lib/systemd/user/swaync.service
)
for systemd_user_unit in "${systemd_user_units[@]}"; do
    systemd_user_enable_start "${systemd_user_unit}"
done

echo "Reloading fonts"
fc-cache || {
    echo "Failed to reload fonts"
    exit 1
}

echo "Reloading udev rules"
sudo udevadm control --reload-rules || {
    echo "Failed to reload udev rules"
    exit 1
}

sudo udevadm trigger || {
    echo "Failed to trigger udev rules"
    exit 1
}
