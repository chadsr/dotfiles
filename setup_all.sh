#!/usr/bin/env bash

BASE_PATH=$PWD
DATA_PATH="$BASE_PATH"/data
SYSTEM_CONFIG="$BASE_PATH"/system
GIT_SUBMODULES="$BASE_PATH"/.git_submodules
GPG_PRIMARY_KEY=0x2B7340DB13C85766
GPG_ENCRYPTION_SUBKEY=0x79C70BBE4865D828

set -euo pipefail
trap 'echo "Error!"' ERR INT

prompt_exit() {
    read -rp "$1 Continue or Abort? (y/N)" answer
    case ${answer:0:1} in
    y | Y)
        return
        ;;
    *)
        exit 0
        ;;
    esac
}

if [ $# -eq 0 ]; then
    echo >&2 "First argument must be <laptop | workstation >"
    exit 1
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

gpg_ssh_agent() {
    unset SSH_AGENT_PID
    if [ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]; then
        export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
    fi
    export GPG_TTY=$(tty)
    gpg-connect-agent updatestartuptty /bye >/dev/null
}

gpg_decrypt_file() {
    gpg -v --local-user "$GPG_ENCRYPTION_SUBKEY" --armor --decrypt --output "${2}" "${1}"
}

gpg_list_dir() {
    gpgtar -v --list-archive --gpg-args "--local-user ${GPG_ENCRYPTION_SUBKEY}" "${1}"
}

gpg_decrypt_dir() {
    gpgtar -v --gpg-args "--local-user ${GPG_ENCRYPTION_SUBKEY}" --decrypt --directory "${2}" "${1}"
}

stow -t ~/ stow || {
    echo "failed to stow stow"
    exit 1
}

echo "Setting up user directory configs"
rm -f ~/.config/mimeapps.list
rm -f ~/.gtkrc-2.0
rm -rf ~/.config/gtk-3.0
rm -rf ~/.config/gtk-4.0

stow -v bash || {
    echo "Failed to stow Bash config"
    exit 1
}

stow -v zsh || {
    echo "Failed to stow ZSH config"
    exit 1
}

stow -v yay || {
    echo "Failed to stow yay config"
    exit 1
}

stow -v systemd || {
    echo "Failed to stow systemd user config"
    exit 1
}

stow -v git || {
    echo "Failed to stow Git config"
    exit 1
}

stow -v gpg || {
    echo "Failed to stow GPG config"
    exit 1
}

echo "Updating package databases & packages"
yay -Syu || {
    echo "failed to update package databases"
    exit 1
}

echo "Installing script dependencies"
yay_install git curl wget make stow gnupg pcsclite ccid inkscape xorg-xcursorgen wayland nano rustup sccache pkg-config meson ninja

rustup default stable || {
    echo "failed to setup rust stable toolchain"
    exit 1
}

# gpg-agent.conf doesn't support ENVs so replace variable here
envsubst <"$DATA_PATH"/gpg/gpg-agent.conf >"$BASE_PATH"/gpg/.gnupg/gpg-agent.conf

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

cp -f "$BASE_PATH"/data/ssh/yk.pub ~/.ssh || {
    echo "failed to copy ssh pubkey"
    exit 1
}

systemctl --user restart gpg-agent || {
    echo "failed to restart GPG agent service"
    exit 1
}

gpg --import "$BASE_PATH"/data/gpg/2B7340DB13C85766.asc || {
    echo "failed to import GPG pubkey"
    exit 1
}

gpg --tofu-policy good "$GPG_PRIMARY_KEY" || {
    echo "failed to set gpg tofu policy"
    exit 1
}

echo "Decrypting ./data files"
gpg_decrypt_file "$DATA_PATH"/ssh/config.asc.gpg "$BASE_PATH"/ssh/.ssh/config
gpg_decrypt_file "$DATA_PATH"/xdg/mimeapps.list.asc.gpg "$BASE_PATH"/sway/.config/mimeapps.list
gpg_decrypt_file "$DATA_PATH"/tidal-hifi/config.json.asc.gpg "$BASE_PATH"/tidal-hifi/.config/tidal-hifi/config.json
gpg_list_dir "$DATA_PATH"/corectrl/profiles.gpgtar
gpg_decrypt_dir "$DATA_PATH"/corectrl/profiles.gpgtar "$BASE_PATH"

stow -v ssh || {
    echo "Failed to stow ssh config"
    exit 1
}

gpg_ssh_agent

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

stow -v sway || {
    echo "Failed to stow Sway config"
    exit 1
}

stow -v hyprland || {
    echo "Failed to stow Hyprland config"
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
    echo "Failed to stow mpv config"
    exit 1
}

echo "Installing Mesa/Vulkan Drivers"
yay_install mesa lib32-mesa mesa-vdpau lib32-mesa-vdpau libva-mesa-driver lib32-libva-mesa-driver libva-utils opencl-rusticl-mesa

if [[ "$1" == "laptop" ]]; then
    echo "Copying laptop system configuration"

    sudo rsync --chown=root:root --open-noatime --progress -ruav "$SYSTEM_CONFIG"/laptop/* /

    echo "Installing Intel/Vulkan Drivers"
    yay_install xf86-video-intel vulkan-intel

    echo "Installing ONNXRuntime"
    yay_install onnxruntime-opt python-onnxruntime-opt

    echo "Checking if TLP is installed"
    yay_install tlp tpacpi-bat acpi_call

    echo "Enable TLP service"
    sudo systemctl enable tlp || {
        echo "failed to enable TLP service"
        exit 1
    }

    echo "Checking if python-validity is installed"
    yay_install python-validity-git

    echo "Enable fprintd resume/suspend services"
    sudo systemctl enable open-fprintd-resume open-fprintd-suspend || {
        echo "failed to enable fprintd resume/suspend services"
        exit 1
    }

elif [[ "$1" == "workstation" ]]; then
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

    sudo rsync --chown=root:root --open-noatime --progress -ruav "$SYSTEM_CONFIG"/workstation/* /

    echo "Installing liquidctl"
    yay_install liquidctl

    symlink "$GIT_SUBMODULES"/liquidctl/extra/yoda.py "$BASE_PATH"/liquidctl/.local/bin/yoda

    stow -v liquidctl || {
        echo "failed to stow liquidctl"
        exit 1
    }

    systemctl --user daemon-reload || {
        echo "failed to daemon-reload"
        exit 1
    }

    systemctl --user enable liquidctl || {
        echo "failed to enable liquidctl user systemd unit"
        exit 1
    }

    systemctl --user enable yoda || {
        echo "failed to enable yoda user systemd unit"
        exit 1
    }

    sudo rm -f /usr/lib/firewalld/services/alvr.xml
    echo "Installing ALVR"
    yay_install alvr-git
else
    exit 1
fi

echo "Copying common system configuration"
sudo rsync --chown=root:root --open-noatime --progress -ruav "$SYSTEM_CONFIG"/common/* /

echo "Adding user to audio group"
sudo groupadd audio || {
    echo "audio group already exists"
}
sudo usermod -a -G audio "$USER"

echo "Copying themes from git repo to dotfiles locations"

cd "$GIT_SUBMODULES"/hackneyed-cursor || {
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

symlink "$GIT_SUBMODULES"/hackneyed-cursor/Hackneyed-Dark "$BASE_PATH"/sway/.icons/hackneyed-dark

make clean || {
    echo "failed to clean hackneyed make files"
    exit 1
}
rm -f ./*.tar.bz2
cd "$BASE_PATH" || {
    echo "failed to cd to ${BASE_PATH}"
    exit 1
}

symlink "$GIT_SUBMODULES"/alacritty-theme/themes "$BASE_PATH"/alacritty/.config/alacritty/colors

symlink "$GIT_SUBMODULES"/sweet-icons/Sweet-Purple "$BASE_PATH"/sway/.icons/sweet-purple

symlink "$GIT_SUBMODULES"/sweet-icons "$BASE_PATH"/sway/.icons/sweet-icons

symlink "$GIT_SUBMODULES"/sweet-theme "$BASE_PATH"/sway/.themes/sweet-theme

symlink "$GIT_SUBMODULES"/candy-icons "$BASE_PATH"/sway/.icons/candy-icons

symlink "$GIT_SUBMODULES"/buuf-nestort-icons "$BASE_PATH"/sway/.icons/buuf-nestort-icons

rmrf "$BASE_PATH"/sway/.themes/materia-cyberpunk-neon
unzip -o "$GIT_SUBMODULES"/cyberpunk-theme/gtk/materia-cyberpunk-neon.zip -d "$BASE_PATH"/sway/.themes || {
    echo "failed copying Cyberpunk-Neon theme to sway"
    exit 1
}

echo "Checking for old dependencies to remove"
yay -R --noconfirm swaylock swaylock-blur pipewire-media-session pipewire-pulseaudio pipewire-pulseaudio-git pulseaudio-equalizer pulseaudio-lirc pulseaudio-zeroconf pulseaudio pulseaudio-bluetooth redshift-wayland-git birdtray alacritty-colorscheme ly || {
    echo "no old dependencies found"
}

echo "Checking for ZSH dependencies to install"
"$GIT_SUBMODULES"/ohmyzsh/tools/install.sh || {
    echo "failed to install oh-my-zsh"
}

yay_install zsh thefuck ttf-meslo-nerd-font-powerlevel10k

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
yay_install nodejs npm nvm electron

echo "Installing QT Dependencies"
yay_install qt5-wayland qt6-wayland qtkeychain-qt5 qtkeychain-qt6 qgnomeplatform-qt5 qgnomeplatform-qt6

echo "Installing GTK Dependencies"
yay_install libappindicator-gtk2 libappindicator-gtk3 xsettingsd

echo "Installing greetd Greeter"
yay_install greetd greetd-regreet

sudo systemctl enable greetd || {
    echo "failed to enable greetd systemd unit"
    exit 1
}

echo "Installing Pipewire dependencies"
yay_install pipewire pipewire-pulse pipewire-alsa wireplumber alsa-tools

echo "Installing Bluetooth dependencies"
yay_install bluez bluez-utils bluez-obex bluetuith-bin

echo "Checking for general utilities dependencies to install"
yay_install gvfs gvfs-smb thunar thunar-volman thunar-shares-plugin mpv smartmontools batsignal mimeo htop udiskie pavucontrol wdisplays ranger shotwell rbw light mako alacritty gnome-keyring cava iniparser fftw bemenu-wayland pinentry-bemenu libnotify kanshi helvum xdg-desktop-portal xdg-desktop-portal-wlr wayland-protocols dex gammastep lxappearance otf-font-awesome ttf-hack dust okular

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

echo "Removing vim"
yay -R --noconfirm vim || {
    echo "vim not installed, skipping removal"
}

echo "Installing  neovim"
yay_install neovim python-pynvim neovim-symlinks

echo "Installing qbitorrent"
yay_install qbittorrent

echo "Installing freetube"
yay_install freetube-bin

echo "Installing Solaar (Logitech manager)"
yay_install solaar

echo "Installing TIDAL-HiFi"
yay_install tidal-hifi-git

echo "Installing Brave"
yay_install brave-bin

echo "Installing Conda/Micromamba"
yay_install miniconda3 conda-zsh-completion micromamba-bin

echo "Installing VSCodium"
yay_install vscodium-bin vscodium-bin-features vscodium-bin-marketplace

echo "Installing Betterbird dependencies"
yay_install betterbird-bin

echo "Installing Video Editing dependencies"
yay_install gyroflow-bin kdenlive

echo "Installing Logseq dependencies"
yay_install logseq-desktop-bin

echo "Installing Nextcloud dependencies"
yay_install nextcloud-client

echo "Installing Steam dependencies"
yay_install steam-native-runtime

echo "Installing GPG / YubiKey dependencies"
yay_install gnupg seahorse pcsclite ccid hopenpgp-tools yubikey-personalization yubikey-manager

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

systemctl --user enable gamemoded.service || {
    echo "failed to enable gamemoded"
    exit 1
}

echo "Enabling batsignal service"
systemctl --user enable batsignal.service || {
    echo "failed to enable batsignal service"
    exit 1
}

systemctl --user start batsignal.service || {
    echo "failed to start batsignal service"
    exit 1
}

echo "Enabling ULauncher service"
systemctl --user enable ulauncher.service || {
    echo "failed to enable ulauncher.service"
    exit 1
}

systemctl --user start ulauncher.service || {
    echo "failed to start ulauncher.service"
    exit 1
}

echo "Enabling Gammastep service"
systemctl --user enable gammastep-wayland.service || {
    echo "failed to enable gammastep-wayland.service"
    exit 1
}

systemctl --user start gammastep-wayland.service || {
    echo "failed to start gammastep-wayland.service"
    exit 1
}

echo "Enabling swayidle service"
systemctl --user enable swayidle.service || {
    echo "failed to enable swayidle.service"
    exit 1
}

systemctl --user start swayidle.service || {
    echo "failed to start swayidle.service"
    exit 1
}

echo "Enabling mako service"
systemctl --user enable mako.service || {
    echo "failed to enable mako.service"
    exit 1
}

systemctl --user start mako.service || {
    echo "failed to start mako.service"
    exit 1
}

echo "Enabling kanshi service"
systemctl --user enable kanshi.service || {
    echo "failed to enable kanshi.service"
    exit 1
}

systemctl --user start kanshi.service || {
    echo "failed to start kanshi.service"
    exit 1
}

echo "Enabling corectrl service"
systemctl --user enable corectrl.service || {
    echo "failed to enable corectrl.service"
    exit 1
}

systemctl --user start corectrl.service || {
    echo "failed to start corectrl.service"
    exit 1
}

echo "Enable lingering for current user"
loginctl enable-linger "${USER}" || {
    echo "failed to enabling lingering"
    exit 1
}
