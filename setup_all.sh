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
        return
        ;;
    *)
        exit_setup
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

yay_install() {
    yay -S --noconfirm --needed --noredownload "${@}" || {
        echo "failed to install:"
        echo "${@}"
        exit 1
    }
}

rmrf() {
    rm -rf "${1}" || {
        echo "failed to recursively remove ${1}"
        exit 1
    }
}

symlink() {
    rmrf "${2}" || {
        echo "failed to remove old symlink: ${2}"
        exit 1
    }
    ln -s "${1}" "${2}" || {
        echo "failed to symlink: ${1} to ${2}"
        exit 1
    }
}

systemd_user_enable_start() {
    systemctl --user enable "${1}"/"${2}"
    systemctl --user start "${2}"
}

gpg_ssh_agent() {
    unset SSH_AGENT_PID
    if [ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]; then
        SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
        export SSH_AUTH_SOCK
    fi
    GPG_TTY=$(tty)
    export GPG_TTY
    gpg-connect-agent updatestartuptty /bye >/dev/null
}

gpg_decrypt_file() {
    gpg -v --local-user "$gpg_encryption_subkey" --armor --decrypt --yes --output "${2}" "${1}"
}

gpg_list_dir() {
    gpgtar -v --list-archive --gpg-args "--local-user ${gpg_encryption_subkey}" "${1}"
}

gpg_decrypt_dir() {
    gpgtar -v --gpg-args "--local-user ${gpg_encryption_subkey}" --decrypt --yes --directory "${2}" "${1}"
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

echo "Updating package databases & packages"
yay -Syu || {
    echo "failehd to update package databases"
    exit 1
}

echo "Installing script dependencies"
yay_install git curl wget make stow gnupg pcsclite ccid inkscape xorg-xcursorgen wayland nano rustup sccache pkg-config meson ninja bemenu-wayland pinentry-bemenu

rustup default stable || {
    echo "failed to setup rust stable toolchain"
    exit 1
}

stow -t ~/ stow || {
    echo "failed to stow stow"
    exit 1
}

echo "Removing broken symlinks in ${HOME}/.config"
find ~/.config/ -xtype l -print -delete || {
    echo "Failed to remove broken symlinks"
    exit 1
}

echo "Setting up user directory configs"

# Parent dirs that should not be symlinks from stow-ing
mkdir -p ~/.local/share
mkdir -p ~/.local/bin
mkdir -p ~/.config/pulse
mkdir -p ~/.config/nvim
mkdir -p ~/.config/systemd/user
mkdir -p ~/.config/environment.d
mkdir -p ~/.config/pulseaudio-ctl
mkdir -p ~/.config/tidal-hifi
mkdir -p ~/.config/ulauncher
mkdir -p ~/.config/corectrl/profiles
mkdir -p ~/.config/bat/themes
mkdir -p ~/.themes
mkdir -p ~/.icons
mkdir -p ~/.cargo
mkdir -p ~/.oh-my-zsh
mkdir -p ~/.config/VSCodium/User/globalStorage/zokugun.sync-settings
mkdir -p ~/.ssh

# Remove existing dirs/files that will cause conflicts
rm -f ~/.config/mimeapps.list
rm -f ~/.gtkrc-2.0
rm -rf ~/.config/gtk-3.0
rm -rf ~/.config/gtk-4.0
rm -f ~/.zshrc
rm -f ~/.zshenv
rm -f ~/.bashrc

stow -v bash || {
    echo "Failed to stow Bash config"
    exit 1
}

source ~/.bashrc || {
    echo "failed to source .bashrc"
    exit 1
}

stow -v yay || {
    echo "Failed to stow yay config"
    exit 1
}

stow -v git || {
    echo "Failed to stow Git config"
    exit 1
}

declare -a old_pkgs=(
    vi vim swaylock swaylock-blur pipewire-media-session pipewire-pulseaudio pipewire-pulseaudio-git pulseaudio-equalizer pulseaudio-lirc pulseaudio-zeroconf pulseaudio pulseaudio-bluetooth redshift-wayland-git birdtray alacritty-colorscheme ly vscodium-bin vscodium-bin-features vscodium-bin-marketplace thunar-shares-plugin
)
echo "Checking for old packages to remove"
for old_pkg in "${old_pkgs[@]}"; do
    yay -R --noconfirm "$old_pkg" || {
        :
    }
done

echo "Checking for ZSH dependencies to install"
yay_install zsh thefuck ttf-meslo-nerd-font-powerlevel10k

read -p "Do you need to install ohmyzsh? (${git_submodule_path}/ohmyzsh/tools/install.sh) (y/N)?" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -r -p "Press enter once the the installation is finished... [enter]"
    rm -f ~/.zshrc
fi

stow -v zsh || {
    echo "Failed to stow ZSH config"
    exit 1
}

# Create ~/.gnupg
gpg --list-keys

stow -v gpg || {
    echo "Failed to stow GPG config"
    exit 1
}

# gpg-agent.conf doesn't support ENVs so replace variable here
envsubst <"$data_path"/gpg/gpg-agent.conf >"$base_path"/gpg/.gnupg/gpg-agent.conf

echo "Setting up GPG/SSH"

echo "Enabling pcscd.socket"
sudo systemctl enable pcscd.socket || {
    echo "failed to enable pcscd.socket"
    exit 1
}

echo "Starting pcscd.socket"
sudo systemctl start pcscd.socket || {
    echo "failed to start pcscd.socket"
    exit 1
}

cp -f "$base_path"/data/ssh/yk.pub ~/.ssh || {
    echo "failed to copy ssh pubkey"
    exit 1
}

chmod 600 ~/.ssh/yk.pub || {
    echo "failed to change permissions on ssh pubkey"
    exit 1
}

systemctl --user restart gpg-agent || {
    echo "failed to restart GPG agent service"
    exit 1
}

gpg --import "$base_path"/data/gpg/2B7340DB13C85766.asc || {
    echo "failed to import GPG pubkey"
    exit 1
}

gpg --tofu-policy good "$gpg_primary_key" || {
    echo "failed to set gpg tofu policy"
    exit 1
}

stow -v ssh || {
    echo "Failed to stow ssh config"
    exit 1
}

gpg_ssh_agent

# Check if certain submodules get updated, so we don't build them uneccessarily
hackneyed_updated=false
hackneyed_hash_old=$(git -C "$git_submodule_path"/hackneyed-cursor rev-parse --short HEAD)

git submodule update --progress --init --force --recursive --remote || {
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

echo "Decrypting ./data files"
gpg_decrypt_file "$data_path"/ssh/config.asc.gpg "$base_path"/ssh/.ssh/config
gpg_decrypt_file "$data_path"/xdg/mimeapps.list.asc.gpg "$base_path"/xdg/.config/mimeapps.list
gpg_decrypt_file "$data_path"/tidal-hifi/config.json.asc.gpg "$base_path"/tidal-hifi/.config/tidal-hifi/config.json
gpg_decrypt_file "$data_path"/gallery-dl/config.json.asc.gpg "$base_path"/gallery-dl/.config/gallery-dl/config.json
gpg_decrypt_file "$data_path"/waybar/crypto/config.ini.asc.gpg "$base_path"/sway/.config/waybar/modules/crypto/config.ini
gpg_decrypt_file "$data_path"/gtk/bookmarks.asc.gpg "$base_path"/gtk/.config/gtk-3.0/bookmarks

stow -v sway || {
    echo "Failed to stow Sway config"
    exit 1
}

stow -v hyprland || {
    echo "Failed to stow Hyprland config"
    exit 1
}

stow -v xdg || {
    echo "Failed to stow xdg config"
    exit 1
}

stow -v bemenu || {
    echo "Failed to stow bemenu config"
    exit 1
}

stow -v ulauncher || {
    echo "Failed to stow ULauncher config"
    exit 1
}

stow -v gammastep || {
    echo "Failed to stow gammastep config"
    exit 1
}

stow -v vim || {
    echo "Failed to stow Vim config"
    exit 1
}

stow -v rust || {
    echo "Failed to stow Rust config"
    exit 1
}

stow -v vscodium || {
    echo "Failed to stow VSCodium config"
    exit 1
}

stow -v logseq || {
    echo "Failed to stow Logseq config"
    exit 1
}

stow -v alacritty || {
    echo "Failed to stow Alacritty config"
    exit 1
}

stow -v ranger || {
    echo "Failed to stow ranger config"
    exit 1
}

stow -v gtk || {
    echo "Failed to stow gtk config"
    exit 1
}

stow -v cava || {
    echo "Failed to stow Cava config"
    exit 1
}

stow -v corectrl || {
    echo "failed to stow corectrl"
    exit 1
}

stow -v tidal-hifi || {
    echo "Failed to stow tidal-hifi config"
    exit 1
}

stow -v mpv || {
    echo "Failed to stow mpv config"
    exit 1
}

stow -v freetube || {
    echo "Failed to stow freetube config"
    exit 1
}

stow -v gallery-dl || {
    echo "Failed to stow gallery-dl config"
    exit 1
}

stow -v bat || {
    echo "Failed to stow bat config"
    exit 1
}

stow -v nextcloud || {
    echo "Failed to stow nextcloud config"
    exit 1
}

echo "Installing Mesa/Vulkan Drivers"
yay_install mesa lib32-mesa mesa-vdpau lib32-mesa-vdpau libva-mesa-driver lib32-libva-mesa-driver libva-utils opencl-rusticl-mesa

if [[ "$current_hostname" == "$laptop_hostname" ]]; then
    echo "Copying laptop system configuration"

    gpg_list_dir "$data_path"/corectrl/"$laptop_hostname"_profiles.gpgtar
    gpg_decrypt_dir "$data_path"/corectrl/"$laptop_hostname"_profiles.gpgtar "$base_path"/corectrl/.config/corectrl

    sudo rsync --chown=root:root --open-noatime --progress -ruav "$system_config_path"/"$laptop_hostname"/* /

    echo "Installing Intel/Vulkan Drivers"
    yay_install xf86-video-intel vulkan-intel

    echo "Installing ONNXRuntime"
    yay_install onnxruntime-opt python-onnxruntime-opt

    yay_install brightnessctl || {
        echo "failed to install brightnessctl"
        exit 1
    }

    echo "Checking if python-validity is installed"
    yay_install python-validity-git

    echo "Enable fprintd resume/suspend services"
    sudo systemctl enable open-fprintd-resume open-fprintd-suspend || {
        echo "failed to enable fprintd resume/suspend services"
        exit 1
    }

    sudo systemctl enable python3-validity.service || {
        echo "failed to enable python3-validity.service"
        exit 1
    }

    sudo systemctl start python3-validity.service || {
        echo "failed to starth python3-validity.service"
        exit 1
    }

    pam_rule="auth      sufficient      pam_fprintd.so max_tries=5 timeout=10"
    read -p "Add PAM fprintd rules? (${pam_rule}) (y/N)?" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo vi /etc/pam.d/sudo
        sudo vi /etc/pam.d/system-local-login
    fi

elif [[ "$current_hostname" == "$desktop_hostname" ]]; then
    echo "Installing Radeon/Vulkan/ROCM drivers"
    yay_install xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon rocm-core rocm-opencl-runtime comgr hipblas rccl

    echo "Installing ROCM ONNXRuntime"
    yay_install onnxruntime-opt-rocm python-onnxruntime-opt-rocm

    # https://wiki.archlinux.org/title/AMDGPU#Boot_parameter
    boot_parameter=$(printf 'amdgpu.ppfeaturemask=0x%x\n' "$(($(cat /sys/module/amdgpu/parameters/ppfeaturemask) | 0x4000))")

    read -p "Add AMDGPU Boot parameter? (${boot_parameter}) (y/N)?" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo vi /etc/default/grub
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi

    gpg_list_dir "$data_path"/corectrl/"$desktop_hostname"_profiles.gpgtar
    gpg_decrypt_dir "$data_path"/corectrl/"$desktop_hostname"_profiles.gpgtar "$base_path"/corectrl/.config/corectrl

    sudo rsync --chown=root:root --open-noatime --progress -ruav "$system_config_path"/"$desktop_hostname"/* /

    echo "Installing liquidctl"
    yay_install liquidctl

    symlink "$git_submodule_path"/liquidctl/extra/yoda.py "$base_path"/liquidctl/.local/bin/yoda

    stow -v liquidctl || {
        echo "failed to stow liquidctl"
        exit 1
    }

    systemctl --user daemon-reload || {
        echo "failed to daemon-reload"
        exit 1
    }

    systemd_user_enable_start "$base_path"/liquidctl/.config/systemd/user liquidctl.service
    systemd_user_enable_start "$base_path"/liquidctl/.config/systemd/user yoda.service

    sudo rm -f /usr/lib/firewalld/services/alvr.xml
    echo "Installing ALVR"
    yay_install alvr-git
fi

echo "Copying common system configuration"
sudo rsync --chown=root:root --open-noatime --progress -ruav "$system_config_path"/common/* /

echo "Adding user to audio group"
sudo groupadd audio || {
    echo "audio group already exists"
}
sudo usermod -a -G audio "$USER"

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

symlink "$git_submodule_path"/alacritty-theme/themes "$base_path"/alacritty/.config/alacritty/colors

symlink "$git_submodule_path"/sweet-icons/Sweet-Purple "$base_path"/gtk/.icons/sweet-purple

symlink "$git_submodule_path"/sweet-icons "$base_path"/gtk/.icons/sweet-icons

symlink "$git_submodule_path"/sweet-theme "$base_path"/gtk/.themes/sweet-theme

symlink "$git_submodule_path"/candy-icons "$base_path"/gtk/.icons/candy-icons

symlink "$git_submodule_path"/buuf-nestort-icons "$base_path"/gtk/.icons/buuf-nestort-icons

symlink "$git_submodule_path"/catppuccin-bat/themes/Catppuccin\ Mocha.tmTheme "$base_path"/bat/.config/bat/themes/Catppuccin-Mocha.tmTheme

rmrf "$base_path"/gtk/.themes/materia-cyberpunk-neon
unzip -o "$git_submodule_path"/cyberpunk-theme/gtk/materia-cyberpunk-neon.zip -d "$base_path"/gtk/.themes || {
    echo "failed copying Cyberpunk-Neon theme"
    exit 1
}

echo "Installing Python dependencies"
yay_install python python-requests

echo "Installing Go toolchain"
yay_install go

echo "Installing Rust toolchain"
yay_install rustup rust-analyzer sccache

rustup update || {
    echo "failed to update Rust toolchain"
    exit 1
}

rustup component add clippy rustfmt || {
    echo "failed to install Rust components"
    exit 1
}

echo "Installing node.js toolchain"
yay_install nodejs npm electron nvm-git

nvm_init_script="source /usr/share/nvm/init-nvm.sh"
if [[ $(line_exists "$nvm_init_script" ~/.zshrc) == 1 ]]; then
    echo "Adding NVM init script to ~/.zshrc"
    echo 'source /usr/share/nvm/init-nvm.sh' >>~/.zshrc
fi

source /usr/share/nvm/init-nvm.sh

nvm install lts/* || {
    echo "failed to install Node LTS"
    exit 1
}

nvm alias default lts/* || {
    echo "failed to set node default version to LTS"
    exit 1
}

echo "Installing Java dependencies"
yay_install jdk-openjdk || {
    echo "Failed to install Java dependencies"
    exit 1
}

echo "Installing QT Dependencies"
yay_install qt5-wayland qt6-wayland qtkeychain-qt5 qtkeychain-qt6 qgnomeplatform-qt5 qgnomeplatform-qt6

echo "Installing GTK Dependencies"
yay_install libappindicator-gtk2 libappindicator-gtk3 xsettingsd-git

echo "Installing greetd Greeter"
yay_install greetd greetd-regreet

sudo systemctl enable greetd || {
    echo "failed to enable greetd systemd unit"
    exit 1
}

echo "Installing Pipewire dependencies"
yay_install pipewire pipewire-pulse pipewire-alsa wireplumber alsa-tools

echo "Installing Bluetooth dependencies"
yay_install bluez bluez-utils bluez-obex bluetuith-git

echo "Checking for general utilities dependencies to install"
yay_install gvfs gvfs-smb thunar thunar-volman thunar-archive-plugin thunar-media-tags-plugin tumbler mpv smartmontools batsignal mimeo htop udiskie pavucontrol wdisplays ranger shotwell rbw light mako alacritty gnome-keyring cava iniparser fftw libnotify kanshi helvum xdg-desktop-portal xdg-desktop-portal-wlr wayland-protocols dex gammastep geoclue lxappearance otf-font-awesome ttf-hack dust okular gallery-dl-git bat nextcloud-client opensnitch hopenpgp-tools ddrescue nmap nm-connection-editor gnome-disk-utility fwupd

bat cache --build || {
    echo "failed to build bat cache"
    exit 1
}

echo "Checking for Sway dependencies to install"
yay_install sway swayidle swaybg wlr-sunclock-git waybar azote slurp grim swappy wl-clipboard wf-recorder grimshot swaylock-effects-git wayvnc ansiweather

echo "Installing Hyprland"
yay_install hyprland

echo "Installing ULauncher"
yay_install ulauncher python-pint python-pytz

echo "Installing corectrl"
yay_install corectrl

corectrl_rules=/etc/polkit-1/rules.d/90-corectrl.rules

if [ ! -f ${corectrl_rules} ]; then
    echo "Setting up polkit for Corectrl"
    (
        echo 'polkit.addRule(function(action, subject) {
if ((action.id == "org.corectrl.helper.init" ||
    action.id == "org.corectrl.helperkiller.init") &&
    subject.local == true &&
    subject.active == true &&
    subject.isInGroup("'"${USER}"'")) {
        return polkit.Result.YES;
    }
});
    '
    ) | sudo tee ${corectrl_rules} || {
        echo "Failed to setup polkit for Corectrl"
        exit 1
    }
fi

echo "Installing gamemode"
yay_install gamemode

echo "Installing obs"
yay_install obs-studio libobs-dev libwayland-dev wlrobs-hg

echo "Installing neovim"
yay_install neovim python-pynvim neovim-symlinks tinyxxd

echo "Installing PlatformIO"
yay_install platformio-core platformio-core-udev

echo "Installing qbitorrent"
yay_install qbittorrent

echo "Installing freetube"
yay_install freetube-git

echo "Installing Solaar (Logitech manager)"
yay_install solaar

echo "Installing TIDAL-HiFi"
yay_install tidal-hifi-git

echo "Installing Conda tooling"
yay_install rattler-build

echo "Installing VSCodium"
yay_install vscodium-git-wayland-hook vscodium-git vscodium-git-features vscodium-git-marketplace

echo "Installing Betterbird dependencies"
yay_install betterbird-bin

echo "Installing Video Editing dependencies"
yay_install gyroflow-git kdenlive

echo "Installing Logseq dependencies"
yay_install logseq-desktop-git

echo "Installing Nextcloud dependencies"
yay_install nextcloud-client

echo "Installing Steam dependencies"
yay_install steam-native-runtime steamtinkerlaunch-git

echo "Installing YubiKey dependencies"
yay_install yubikey-personalization yubikey-manager yubikey-manager-qt

echo "Disabling GNOME Keyring SSH Agent"

sudo systemctl disable gcr-ssh-agent.socket || {
    :
}

sudo systemctl disable gcr-ssh-agent.service || {
    :
}

echo "Enabling smartd service"
sudo systemctl enable smartd.service || {
    echo "failed to enable smartd service"
    exit 1
}

sudo sudo systemctl start smartd.service || {
    echo "failed to start smartd service"
    exit 1
}

sudo systemctl enable bluetooth.service || {
    echo "failed to enable bluetoorh service"
    exit 1
}

sudo systemctl start bluetooth.service || {
    echo "failed to start bluetoorh service"
    exit 1
}

echo "Reloading Systemd user daemon"
systemctl --user daemon-reload || {
    echo "failed to userspace daemon-reload"
    exit 1
}

systemctl --user restart wireplumber pipewire pipewire-pulse.service pipewire-pulse.socket || {
    echo "failed to restart pipewire"
    exit 1
}

systemd_user_enable_start /usr/lib/systemd/user gamemoded.service
systemd_user_enable_start /usr/lib/systemd/user batsignal.service
systemd_user_enable_start /usr/lib/systemd/user ulauncher.service
systemd_user_enable_start /usr/lib/systemd/user mako.service

systemd_user_enable_start "$base_path"/gtk/.config/systemd/user xsettingsd.service
systemd_user_enable_start "$base_path"/gammastep/.config/systemd/user geoclue-agent.service
systemd_user_enable_start "$base_path"/gammastep/.config/systemd/user gammastep-wayland.service
systemd_user_enable_start "$base_path"/sway/.config/systemd/user sway-session.target
systemd_user_enable_start "$base_path"/sway/.config/systemd/user swayidle.service
systemd_user_enable_start "$base_path"/sway/.config/systemd/user kanshi.service
systemd_user_enable_start "$base_path"/corectrl/.config/systemd/user corectrl.service
systemd_user_enable_start "$base_path"/nextcloud/.config/systemd/user nextcloud-client.service

echo "Enable lingering for current user"
# Prevents user systemd units from getting killed
loginctl enable-linger "${USER}" || {
    echo "failed to enabling lingering"
    exit 1
}

echo "Reloading udev rules"
sudo udevadm control --reload-rules && sudo udevadm trigger
