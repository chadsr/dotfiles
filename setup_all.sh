#!/usr/bin/env bash

base_path=$PWD
data_path="$base_path"/data
system_config_path="$base_path"/system
git_submodule_path="$base_path"/.git_submodules

gpg_primary_key=0x2B7340DB13C85766
gpg_encryption_subkey=0x79C70BBE4865D828

laptop_hostname="thinky"
desktop_hostname="shifty"
current_hostname=$(hostname)

tmp_path=/tmp/setup-"$current_hostname"

package_manager=/usr/bin/yay
pkglist_system_path=/etc/pkglist.txt

# bare minimum packages needed by this script in order to bootstrap
declare -a script_pkgs=(
    gnupg
    neovim
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
    system_config_full_path="$system_config_path"/"${1}"

    if [[ ! -d "$system_config_full_path" ]]; then
        echo "The provided path '${system_config_full_path}' does not exist!"
        return 1
    fi

    sudo rsync --chown=root:root --open-noatime --progress -ruacv -- "${system_config_full_path}"/* / || {
        echo "failed to rsync system config from ${system_config_full_path} to root filesystem"
        return 1
    }
}

systemd_enable_start() {
    unit_path="${1}"
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
    unit_path="${1}"
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

is_binary() {
    LC_MESSAGES=C grep -Hm1 '^' <"${1-$REPLY}" | grep -q '^Binary'
}

diff_files() {
    if [[ ! -f "$1" ]]; then
        echo "file ${1} does not exist"
        return 1
    fi
    if [[ ! -f "$2" ]]; then
        echo "file ${2} does not exist"
        return 1
    fi

    if (cmp -s "$1" "$2"); then
        # If they are identical, then return
        return 0
    else
        if is_binary "{$1}" || is_binary "${2}"; then
            echo "File is binary. Skipping interactive diff"
            return 0
        fi
        vimdiff -d "$1" "$2" || {
            echo "vimdiff on ${1} <-> ${2}' exited with error"
            return 1
        }
    fi
}

# gpg is used directly throughout this setup process
# to handle the non-deterministic nature of gpg encryption, checks/diffs are performed to prevent unwanted changes going un-noticed
gpg_decrypt_file() {
    if [[ ! -f "$1" ]]; then
        echo "input file ${1} does not exist"
        return 1
    fi

    input_file_path="${1}"
    output_file_path="${2}"
    output_filename=$(basename "${output_file_path}")
    tmp_output_file_path="${tmp_path}/${output_filename}"

    echo "Decrypting ${input_file_path} to ${tmp_output_file_path}"

    gpg --local-user "${gpg_encryption_subkey}" --armor --decrypt --yes --output "${tmp_output_file_path}" "${input_file_path}" || {
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
    efi_loader_conf_path=/efi/loader/loader.conf
    kernel_suffix="${1}".conf

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
        symlink_path=$(readlink -f "${1}")
        if [[ $symlink_path == *"${base_path}"* ]]; then
            return 0
        fi
    fi

    rm -rfv "${1}"
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

echo "Setting up user directory configs"

# Parent dirs that should not be symlinks from stow-ing
declare -a mk_dirs=(
    ~/.cargo
    ~/.config/bat/themes
    ~/.config/corectrl/profiles
    ~/.config/environment.d
    ~/.config/khal
    ~/.config/nvim
    ~/.config/pulse
    ~/.config/pulseaudio-ctl
    ~/.config/systemd/user
    ~/.config/Thunar
    ~/.config/tidal-hifi
    ~/.config/VSCodium/User/globalStorage/zokugun.sync-settings
    ~/.config/xfce4/xfconf/xfce-perchannel-xml
    ~/.gnupg
    ~/.icons
    ~/.local/bin
    ~/.local/share/fonts
    ~/.ssh
    ~/.themes
    ~/.vscode-oss
    ~/Pictures/Screenshots
)
for mk_dir in "${mk_dirs[@]}"; do
    mkdir -p "${mk_dir}"
done

declare -a conflict_paths=(
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
    ~/.zshenv
    ~/.zshrc
)
echo "Checking for files/directories that will conflict with stow"
for conflict_path in "${conflict_paths[@]}"; do
    rm_if_not_stowed "${conflict_path}"
done

declare -a stow_dirs_setup=(
    stow
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

# gpg-agent.conf doesn't support ENVs so replace variable here
envsubst <"$data_path"/gpg/gpg-agent.conf >"$base_path"/gpg/.gnupg/gpg-agent.conf

systemd_user_enable_start "$base_path"/gpg/.config/systemd/user/gnupghome.service
systemd_user_enable_start "$base_path"/gpg/.config/systemd/user/ssh-auth-sock.service
systemd_user_enable_start /usr/lib/systemd/user/gpg-agent.service

gpg_ssh_agent

# If our primary GPG key is not yet imported, do that and
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
    "${data_path}/corectrl/${current_hostname}_steam.sh.ccpro.asc.gpg ${base_path}/corectrl/.config/corectrl/profiles/_steam.sh.ccpro"
    "${data_path}/corectrl/${current_hostname}_codium.ccpro.asc.gpg ${base_path}/corectrl/.config/corectrl/profiles/codium.ccpro"
    "${data_path}/gallery-dl/config.json.asc.gpg ${base_path}/gallery-dl/.config/gallery-dl/config.json"
    "${data_path}/gtk/bookmarks.asc.gpg ${base_path}/gtk/.config/gtk-3.0/bookmarks"
    "${data_path}/khal/config.asc.gpg ${base_path}/khal/.config/khal/config"
    "${data_path}/pkgs/remove.txt.asc.gpg ${pkglist_remove_path}"
    "${data_path}/ssh/config.asc.gpg ${base_path}/ssh/.ssh/config"
    "${data_path}/tidal-hifi/config.json.asc.gpg ${base_path}/tidal-hifi/.config/tidal-hifi/config.json"
    "${data_path}/vdirsyncer/config.asc.gpg ${base_path}/khal/.config/vdirsyncer/config"
    "${data_path}/waybar/crypto/config.ini.asc.gpg ${base_path}/waybar/.config/waybar/modules/crypto/config.ini"
    "${data_path}/xdg/mimeapps.list.asc.gpg ${base_path}/xdg/.config/mimeapps.list"
)
for decrypt_data_paths_tuple in "${decrypt_data_paths_tuples[@]}"; do
    read -ra decrypt_data_paths <<<"$decrypt_data_paths_tuple"
    gpg_decrypt_file "${decrypt_data_paths[0]}" "${decrypt_data_paths[1]}"
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
)
for user_group in "${user_groups[@]}"; do
    echo "Adding user to group ${user_group}"
    add_group_user "$user_group"
done

declare -a systemd_units=(
    /usr/lib/systemd/system/bluetooth.service
    /usr/lib/systemd/system/greetd.service
    /usr/lib/systemd/system/pcscd.socket
    /usr/lib/systemd/system/power-profiles-daemon.service
    /usr/lib/systemd/system/smartd.service
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

# https://espanso.org/docs/install/linux/#adding-the-required-capabilities
sudo setcap "cap_dac_override+p" "$(which espanso)" || {
    echo "failed to setcap for espanso"
    exit 1
}

# For some unknown reason some apps (VSCode) seem to have this path hard-coded and refused to listen for env-vars
if [[ ! -e /usr/lib/ssh/ssh-askpass ]]; then
    echo "Symlinking ssh-askpass from Seahorse"
    sudo ln -s /usr/lib/seahorse/ssh-askpass /usr/lib/ssh/ssh-askpass | {
        echo "Failed to symlink ssh-askpass"
        exit 1
    }
fi

if [[ "$current_hostname" == "$laptop_hostname" ]]; then
    pam_rule="auth      sufficient      pam_fprintd.so max_tries=5 timeout=10"
    read -p "Add PAM fprintd rules? (${pam_rule}) (y/N)?" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo vi /etc/pam.d/sudo
        sudo vi /etc/pam.d/system-local-login
    fi

    declare -a systemd_units_laptop=(
        /usr/lib/systemd/system/open-fprintd-resume.service
        /usr/lib/systemd/system/open-fprintd-suspend.service
        /usr/lib/systemd/system/python3-validity.service
    )
    for systemd_unit in "${systemd_units_laptop[@]}"; do
        systemd_enable_start "${systemd_unit}"
    done

    echo "Copying laptop system configuration"
    rsync_system_config "$laptop_hostname"/
elif [[ "$current_hostname" == "$desktop_hostname" ]]; then
    declare -a stow_dirs_desktop=(
        liquidctl
    )

    echo "Stowing ${desktop_hostname} configs"
    for stow_dir in "${stow_dirs_desktop[@]}"; do
        stow_config "$stow_dir"
    done

    set_default_kernel zen

    # Update amdgpu boot parameter
    # https://wiki.archlinux.org/title/AMDGPU#Boot_parameter
    amdgpu_key="amdgpu.ppfeaturemask"
    cmd_line_file_path=/etc/kernel/cmdline
    amdgpu_boot_parameter=$(printf '%s=0x%x\n' "$amdgpu_key" "$(($(cat /sys/module/amdgpu/parameters/ppfeaturemask) | 0x4000))")
    if sudo test -f "$cmd_line_file_path"; then
        if ! string_exists "$amdgpu_key" "$cmd_line_file_path"; then
            echo "Appending boot parameter '$amdgpu_boot_parameter' to $cmd_line_file_path"
            echo " $amdgpu_boot_parameter" | sudo tee -a "$cmd_line_file_path" >/dev/null
            sudo reinstall-kernels | {
                echo "failed to re-install kernels"
                exit 1
            }
        else
            echo "${amdgpu_key} already exists in ${cmd_line_file_path}. skipping."
        fi
    else
        echo "${cmd_line_file_path} does not exist!"
        exit 1
    fi

    symlink "$git_submodule_path"/liquidctl/extra/yoda.py ./liquidctl/.local/bin/yoda

    systemctl --user daemon-reload || {
        echo "failed to daemon-reload"
        exit 1
    }

    declare -a systemd_user_units_desktop=(
        "$base_path"/liquidctl/.config/systemd/user/liquidctl.service
        "$base_path"/liquidctl/.config/systemd/user/yoda.service
    )
    for systemd_user_unit in "${systemd_user_units_desktop[@]}"; do
        systemd_user_enable_start "${systemd_user_unit}"
    done

    echo "Copying desktop system configuration"
    rsync_system_config "$desktop_hostname"/
fi

echo "Copying common system configuration"
rsync_system_config common/

# Check if certain submodules get updated, so we don't build them uneccessarily
hackneyed_updated=false
hackneyed_hash_old=$(git -C "$git_submodule_path"/hackneyed-cursor rev-parse --short HEAD)

swaync_cp_updated=false
swaync_cp_hash_old=$(git -C "$git_submodule_path"/catppuccin-swaync rev-parse --short HEAD)

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

swaync_cp_hash_new=$(git -C "$git_submodule_path"/catppuccin-swaync rev-parse --short HEAD)
if [[ "$swaync_cp_hash_old" != "$swaync_cp_hash_new" ]]; then
    swaync_cp_updated=true
    echo "catppuccin-swaync has been updated"
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

if [[ $swaync_cp_updated == true ]]; then
    cd "$git_submodule_path"/catppuccin-swaync
    npm i --no-package-lock || {
        echo "Failed to install catppuccin-swaync node dependencies"
        exit 1
    }
    npm run build || {
        echo "Failed to build catppuccin-swaync styles"
        exit 1
    }
    cd "$base_path"
fi

declare -a symlink_paths_tuples=(
    "${git_submodule_path}/alacritty-theme/themes ${base_path}/alacritty/.config/alacritty/colors"
    "${git_submodule_path}/buuf-nestort-icons ${base_path}/gtk/.icons/buuf-nestort-icons"
    "${git_submodule_path}/candy-icons ${base_path}/gtk/.icons/candy-icons"
    # "${git_submodule_path}/catppuccin-bat/themes/Catppuccin\ Mocha.tmTheme ${base_path}/bat/.config/bat/themes/Catppuccin-Mocha.tmTheme" # TODO: re-enable due to spacing
    "${git_submodule_path}/catppuccin-helix/themes/default/catppuccin_mocha.toml ${base_path}/helix/.config/helix/themes/catppuccin_mocha.toml"
    "${git_submodule_path}/cryptocoins-icons/webfont/cryptocoins.ttf ${base_path}/fonts/.local/share/fonts/cryptocoins.ttf"
    "${git_submodule_path}/rofi-network-manager/rofi-network-manager.sh ${base_path}/rofi/.local/bin/rofi-network-manager"
    "${git_submodule_path}/swaylock-corrupter/swaylock-corrupter ${base_path}/sway/.local/bin/swaylock-corrupter"
    "${git_submodule_path}/sweet-icons ${base_path}/gtk/.icons/sweet-icons"
    "${git_submodule_path}/sweet-icons/Sweet-Purple ${base_path}/gtk/.icons/sweet-purple"
    "${git_submodule_path}/sweet-theme ${base_path}/gtk/.themes/sweet-theme"
    "${git_submodule_path}/waybar-crypto/waybar_crypto.py ${base_path}/waybar/.config/waybar/modules/crypto/waybar_crypto"
    # "${git_submodule_path}/catppuccin-swaync/dist/mocha.css ${base_path}/sway/.config/swaync/mocha.css"
)
for symlink_paths_tuple in "${symlink_paths_tuples[@]}"; do
    read -ra symlink_paths <<<"$symlink_paths_tuple"
    symlink "${symlink_paths[0]}" "${symlink_paths[1]}"
done

unzip -q -u -o "$git_submodule_path"/cyberpunk-theme/gtk/materia-cyberpunk-neon.zip -d "$base_path"/gtk/.themes || {
    echo "failed copying Cyberpunk-Neon theme"
    exit 1
}

declare -a stow_dirs_general=(
    alacritty
    bat
    bemenu
    cava
    corectrl
    electron
    espanso
    fonts
    freetube
    fuzzel
    gallery-dl
    gamemode
    gammastep
    gtk
    helix
    hyprland
    java
    khal
    logseq
    mpv
    nextcloud
    nvim
    omz
    qt
    ranger
    rofi
    sway
    systemd
    thunar
    tidal-hifi
    ulauncher
    vscodium
    waybar
    xdg
    yt-dlp
    yubikey
)

echo "Stowing general configs"
for stow_dir in "${stow_dirs_general[@]}"; do
    stow_config "$stow_dir"
done

nvm_init_script="source /usr/share/nvm/init-nvm.sh"
if ! line_exists "$nvm_init_script" ~/.zshrc; then
    echo "Adding NVM init script to ~/.zshrc"
    echo 'source /usr/share/nvm/init-nvm.sh' >>~/.zshrc
fi

# shellcheck disable=SC1091
source /usr/share/nvm/init-nvm.sh

nvm install lts/* || {
    echo "failed to install Node LTS"
    exit 1
}

nvm alias default lts/* || {
    echo "failed to set node default version to LTS"
    exit 1
}

bat cache --build || {
    echo "failed to build bat cache"
    exit 1
}

echo "Enabling/Starting Systemd User Units"
systemctl --user daemon-reload || {
    echo "failed to userspace systemd daemon-reload"
    exit 1
}

declare -a systemd_user_units=(
    "$base_path"/corectrl/.config/systemd/user/corectrl.service
    "$base_path"/espanso/.config/systemd/user/espanso.service
    "$base_path"/gammastep/.config/systemd/user/gammastep-wayland.service
    "$base_path"/gammastep/.config/systemd/user/geoclue-agent.service
    "$base_path"/gtk/.config/systemd/user/xsettingsd.service
    "$base_path"/khal/.config/systemd/user/vdirsyncer-sync.service
    "$base_path"/khal/.config/systemd/user/vdirsyncer-sync.timer
    "$base_path"/nextcloud/.config/systemd/user/nextcloud-client.service
    "$base_path"/sway/.config/systemd/user/avizo.service
    "$base_path"/sway/.config/systemd/user/kanshi.service
    "$base_path"/sway/.config/systemd/user/swayidle.service
    "$base_path"/sway/.config/systemd/user/wlr-sunclock.service
    "$base_path"/systemd/.config/systemd/user/enable-linger.service
    /usr/lib/systemd/user/batsignal.service
    /usr/lib/systemd/user/gnome-keyring-daemon.service
    /usr/lib/systemd/user/gnome-keyring-daemon.socket
    /usr/lib/systemd/user/pipewire-pulse.service
    /usr/lib/systemd/user/pipewire-pulse.socket
    /usr/lib/systemd/user/pipewire.service
    /usr/lib/systemd/user/swaync.service
    /usr/lib/systemd/user/wireplumber.service
    /usr/lib/systemd/user/yubikey-touch-detector.service
    /usr/lib/systemd/user/yubikey-touch-detector.socket
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
