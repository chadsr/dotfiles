#!/usr/bin/env bash

BASE_PATH=$PWD
SYSTEM_CONFIG="$BASE_PATH"/system
GIT_SUBMODULES="$BASE_PATH"/.git_submodules
GPG_KEY=2B7340DB13C85766

set -euo pipefail
trap 'echo "Error!"' ERR INT

prompt_exit() {
    read -rp "$1 Continue (y/N)? " answer
    case ${answer:0:1} in
    y | Y)
        return
        ;;
    *)
        exit 0
        ;;
    esac
}

prompt_exit "This script will remove/change existing system settings"

yay_install() {
    yay -S --noconfirm --needed --noredownload "${@}" || {
        echo "failed to install:"
        echo "${@}"
        exit 1
    }
}

rcopy() {
    rsync --ignore-missing-args --open-noatime --progress -ruav "${1}" "${2}" || {
        echo "failed to copy with rsync: ${1} to ${2}"
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

gpg_decrypt() {
    gpg --default-key "$GPG_KEY" -a -d -o "${2}" "${1}"
}

echo "Updating package databases & packages"
yay -Syu || {
    echo "failed to update package databases"
    exit 1
}

echo "Installing script dependencies"
yay_install git curl wget make stow gnupg pcsclite ccid inkscape xorg-xcursorgen

stow -t ~/ stow || {
    echo "failed to stow stow"
    exit 1
}

echo "Setting up user directory configs"
rm -f ~/.config/mimeapps.list
rm -f ~/.gtkrc-2.0
rm -rf ~/.config/gtk-3.0
rm -rf ~/.config/gtk-4.0

stow -v zsh || {
    echo "Failed to stow ZSH config"
    exit 1
}

stow -v systemd || {
    echo "Failed to stow systemd user config"
    exit 1
}

stow -v gpg || {
    echo "Failed to stow GPG config"
    exit 1
}

stow -v sway || {
    echo "Failed to stow Sway config"
    exit 1
}

stow -v hypr || {
    echo "Failed to stow Hyprland config"
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

stow -v git || {
    echo "Failed to stow Git config"
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

stow -v tidal-hifi || {
    echo "Failed to stow tidal-hifi config"
    exit 1
}

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

gpg --tofu-policy good 0x2B7340DB13C85766 || {
    echo "failed to set gpg tofu policy"
    exit 1
}

echo "Decrypting ./data files"
gpg_decrypt "$BASE_PATH"/data/ssh/config.asc.gpg "$BASE_PATH"/ssh/.ssh/config
gpg_decrypt "$BASE_PATH"/data/tidal-hifi/config.json.asc.gpg "$BASE_PATH"/tidal-hifi/.config/tidal-hifi/config.json

stow -v ssh || {
    echo "Failed to stow ssh config"
    exit 1
}

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

if [ "$1" == "laptop" ]; then
    echo "Copying laptop system configuration"

    rcopy "$SYSTEM_CONFIG"/laptop/* /

    echo "Checking if mesa is installed"
    yay_install mesa lib32-mesa xf86-video-intel vulkan-intel

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

elif [ "$1" == "workstation" ]; then
    echo "Installing Radeon/Mesa/Vulkan drivers"
    yay_install mesa lib32-mesa xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau libva-utils

    rcopy "$SYSTEM_CONFIG"/workstation/* /

    echo "Installing liquidctl"
    yay_install liquidctl

    symlink "$GIT_SUBMODULES"/liquidctl/extra/yoda.py "$BASE_PATH"/liquidctl/.local/bin/yoda

    stow -v liquidctl || {
        echo "failed to stow liquidctl"
        exit 1
    }

    stow -v corectrl || {
        echo "failed to stow corectrl"
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
else
    echo "$0: first argument must be <laptop|workstation>"
    exit 1
fi

echo "Copying common system configuration"
rcopy "$SYSTEM_CONFIG"/common/* /

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

rmrf "$BASE_PATH"/sway/.themes/materia-cyberpunk-neon
unzip -o "$GIT_SUBMODULES"/cyberpunk-theme/gtk/materia-cyberpunk-neon.zip -d "$BASE_PATH"/sway/.themes || {
    echo "failed copying Cyberpunk-Neon theme to sway"
    exit 1
}

echo "Checking for old dependencies to remove"
yay -R --noconfirm swaylock-blur pipewire-media-session pipewire-pulseaudio pipewire-pulseaudio-git pulseaudio-equalizer pulseaudio-lirc pulseaudio-zeroconf pulseaudio pulseaudio-bluetooth redshift-wayland-git birdtray || {
    echo "no old dependencies found"
}

echo "Checking for ZSH dependencies to install"
nohup sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >/dev/null 2>&1 & # This will fail if already installed, so don"t bother checking

yay_install zsh thefuck ttf-meslo-nerd-font-powerlevel10k

echo "Checking for general utilities dependencies to install"
yay_install gvfs gvfs-smb thunar thunar-shares-plugin smartmontools batsignal blueman bluez bluez-utils bluez-obex bluetuith

echo "Checking for Sway dependencies to install"
yay_install sway libnotify wlr-sunclock-git xsettingsd kanshi helvum pipewire-pulse pipewire-alsa wireplumber alsa-tools wlsunset xdg-desktop-portal xdg-desktop-portal-wlr pavucontrol wayland-protocols pipewire wdisplays ranger shotwell rbw light waybar libappindicator-gtk2 libappindicator-gtk3 dex otf-font-awesome ttf-hack python python-requests networkmanager-dmenu-git azote slurp grim swappy wl-clipboard wf-recorder grimshot swaylock-effects-git mako gammastep alacritty alacritty-colorscheme udiskie wayvnc ansiweather gnome-keyring cava iniparser fftw bemenu-wayland pinentry-bemenu

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
yay_install obs-studio wlrobs-hg

echo "Removing vim"
yay -R --noconfirm vim || {
    echo "vim not installed, skipping removal"
}

echo "Installing  neovim"
yay_install neovim python-pynvim neovim-symlinks

echo "Installing qbitorrent"
yay_install qbittorrent

echo "Installing Solaar (Logitech manager)"
yay_install solaar

echo "Installing TIDAL-HiFi"
yay_install tidal-hifi-git

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
yay_install nodejs npm nvm

echo "Installing Conda"
yay_install micromamba-bin conda-zsh-completion

echo "Installing VSCodium"
yay_install vscodium-bin vscodium-bin-features vscodium-bin-marketplace

echo "Installing Thunderbird dependencies"
yay_install thunderbird

echo "Installing Logseq dependencies"
yay_install logseq

echo "Installing GPG / YubiKey dependencies"
yay_install gnupg seahorse pcsclite ccid hopenpgp-tools yubikey-agent yubikey-personalization yubikey-manager

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

echo "Reloading Systemd user daemon"
systemctl --user daemon-reload || {
    echo "failed to userspace daemon-reload"
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

echo "Enable lingering for current user"
loginctl enable-linger "${USER}" || {
    echo "failed to enabling lingering"
    exit 1
}
