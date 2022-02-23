#!/usr/bin/env bash

BASE_PATH=$PWD
SYSTEM_CONFIG="$BASE_PATH"/system
GIT_SUBMODULES="$BASE_PATH"/.git_submodules

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

echo "Updating package databases"
yay -Syy || {
    echo "failed to update package databases"
    exit 1
}

stow -t ~/ stow || {
    echo "failed to stow stow"
    exit 1
}

git submodule update -f --init --recursive || {
    echo "failed to update git submodules"
    exit 1
}

git submodule foreach --recursive git fetch || {
    echo "failed to fetch git submodule updates"
    exit 1
}

if [ "$1" == "laptop" ]; then
    echo "Checking if TLP is installed"
    yay -S --noconfirm --needed --noredownload tpacpi-bat tlp || {
        echo "failed to install TLP packages"
        exit 1
    }

    echo "Enable TLP service"
    sudo systemctl enable tlp || {
        echo "failed to enable TLP service"
        exit 1
    }

    echo "Checking if python-validity is installed"
    yay -S --noconfirm --needed --noredownload python-validity-git || {
        echo "failed to install python-validity"
        exit 1
    }

    echo "Enable fprintd resume/suspend services"
    sudo systemctl enable open-fprintd-resume open-fprintd-suspend || {
        echo "failed to enable fprintd resume/suspend services"
        exit 1
    }

    # echo "Checking if throttled is installed"
    # yay -S --noconfirm --needed --noredownload throttled || {
    #     echo "failed to install throttled"
    #     exit 1
    # }

    echo "Copying laptop system configuration"
    sudo rsync -av "$SYSTEM_CONFIG"/laptop / || {
        echo "failed copying laptop configuration"
        exit 1
    }
elif [ "$1" == "workstation" ]; then
    echo "Installing Radeon/Mesa/Vulkan drivers"
    yay -S --noconfirm --needed --noredownload mesa lib32-mesa xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau || {
        echo "failed to install Radeon/Mesa/Vulkan drivers"
        exit 1
    }

    sudo rsync -av "$SYSTEM_CONFIG"/workstation / || {
        echo "failed copying workstation configuration"
        exit 1
    }

    sudo systemctl enable cpupower || {
        echo "failed to enable cpupower systemd unit"
        exit 1
    }

    echo "Installing liquidctl"
    yay -S --noconfirm --needed --combinedupgrade --batchinstall --noredownload liquidctl || {
        echo "failed to install liquidctl dependencies"
        exit 1
    }

    stow -v liquidctl || {
        echo "failed to stow liquidctl"
        exit 1
    }

    stow -v corectrl || {
        echo "failed to stow corectrl"
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

cd "$GIT_SUBMODULES"/punk_theme || {
    echo "failed to cd to ${GIT_SUBMODULES}/punk_theme"
    exit 1
}
git checkout --force origin/Ultimate-Punk-Complete-Desktop || {
    echo "failed to checkout updates"
    exit 1
}

cd "$GIT_SUBMODULES"/Cyberpunk-Neon || {
    echo "failed to cd to ${GIT_SUBMODULES}/Cyberpunk-Neon"
    exit 1
}
git checkout --force origin/master || {
    echo "failed to checkout updates"
    exit 1
}

cd "$GIT_SUBMODULES"/waybar-modules || {
    echo "failed to cd to ${GIT_SUBMODULES}/waybar-modules"
    exit 1
}
git checkout --force origin/master || {
    echo "failed to checkout updates"
    exit 1
}

cd "$BASE_PATH"/sway/.config/waybar/modules/crypto || {
    echo "failed to cd to ${BASE_PATH}/sway/.config/waybar/modules/crypto"
    exit 1
}
git checkout --force origin/master || {
    echo "failed to checkout updates"
    exit 1
}

cd "$BASE_PATH"/zsh/.oh-my-zsh/themes/powerlevel10k || {
    echo "failed to cd to ${BASE_PATH}/zsh/.oh-my-zsh/themes/powerlevel10k"
    exit 1
}
git checkout --force origin/master || {
    echo "failed to checkout updates"
    exit 1
}

cd "$BASE_PATH" || {
    echo "failed to cd back to ${BASE_PATH}"
    exit 1
}

echo "Copying common system configuration"
sudo rsync -av "$SYSTEM_CONFIG"/common/* /

echo "Adding user to audio group"
sudo groupadd audio
sudo usermod -a -G audio "$USER"

echo "Copying themes from git repo to dotfiles locations"
rsync -av "$GIT_SUBMODULES"/punk_theme/Ultimate-PUNK-Cyan-Cursor "$BASE_PATH"/sway/.icons || {
    echo "failed copying Ultimate-PUNK-Cyan-Cursor to sway"
    exit 1
}
rsync -av "$GIT_SUBMODULES"/punk_theme/Ultimate-Punk-Suru++ "$BASE_PATH"/sway/.icons || {
    echo "failed copying Ultimate-Punk-Suru++ to sway"
    exit 1
}

unzip -o "$GIT_SUBMODULES"/Cyberpunk-Neon/gtk/materia-cyberpunk-neon.zip -d "$BASE_PATH"/sway/.themes || {
    echo "failed copying Cyberpunk-Neon theme to sway"
    exit 1
}

rsync -av "$GIT_SUBMODULES"/sweet-theme "$BASE_PATH"/sway/.themes || {
    echo "failed copying sweet-theme to sway"
    exit 1
}

echo "Checking for ZSH dependencies to install"
nohup sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >/dev/null 2>&1 & # This will fail if already installed, so don"t bother checking

yay -S --noconfirm --needed --combinedupgrade --batchinstall --noredownload zsh thefuck ttf-meslo-nerd-font-powerlevel10k || {
    echo "failed to install ZSH config dependencies"
    exit 1
}

echo "Checking for old dependencies to remove"
yay -R --noconfirm swaylock-blur pipewire-media-session pipewire-pulseaudio pipewire-pulseaudio-git pulseaudio-equalizer pulseaudio-lirc pulseaudio-zeroconf pulseaudio pulseaudio-bluetooth redshift-wayland-git

echo "Checking for Sway dependencies to install"
yay -S --noconfirm --needed --combinedupgrade --batchinstall --noredownload sway libnotify wlr-sunclock-git xsettingsd kanshi helvum pipewire-pulse pipewire-alsa wireplumber pulseaudio-alsa alsa-tools xdg-desktop-portal wlsunset libpipewire02 xdg-desktop-portal-wlr pavucontrol qt5-base qt5-wayland wayland-protocols pipewire wdisplays gdk-pixbuf2 ranger shotwell rbw rofi-rbw light waybar libappindicator-gtk2 libappindicator-gtk3 dex rofi otf-font-awesome nerd-fonts-hack ttf-hack python python-requests networkmanager-dmenu azote slurp grim swappy wl-clipboard wf-recorder grimshot swaylock-effects-git mako gammastep gtk-engines alacritty udiskie wayvnc ansiweather qgnomeplatform qgnomeplatform-qt6 || {
    echo "failed to install Sway dependencies"
    exit 1
}

echo "Installing corectrl"
yay -S --noconfirm --needed --combinedupgrade --batchinstall --noredownload corectrl || {
    echo "failed to install corectrl dependencies"
    exit 1
}

corectrl_rules=/etc/polkit-1/rules.d/90-corectrl.rules

if [ ! -f ${corectrl_rules} ]; then
    echo "Setting up polkit for Corectrl"
    (
        echo 'polkit.addRule(function(action, subject) {
if ((action.id == "org.corectrl.helper.init" ||
    action.id == "org.corectrl.helperkiller.init") &&
    subject.local == true &&
    subject.active == true &&
    subject.isInGroup("'${USER}'")) {
        return polkit.Result.YES;
    }
});
    '
    ) | sudo tee ${corectrl_rules} || {
        echo "Failed to setup polkit for Corectrl"
        exit 1
    }
fi

echo "Installing obs"
yay -S --noconfirm --needed --combinedupgrade --batchinstall --noredownload obs-studio wlrobs-hg || {
    echo "failed to install git flow"
    exit 1
}

echo "Removing vim"
yay -R --noconfirm vim

echo "Installing  neovim"
yay -S --noconfirm --needed --combinedupgrade --batchinstall --noredownload neovim python-pynvim neovim-symlinks || {
    echo "failed to install neovim"
    exit 1
}

echo "Installing git flow"
yay -S --noconfirm --needed --combinedupgrade --batchinstall --noredownload gitflow-avh || {
    echo "failed to install git flow"
    exit 1
}

echo "Installing VSCodium"
yay -S --noconfirm --needed --combinedupgrade --batchinstall --noredownload vscodium-bin vscodium-bin-features vscodium-bin-marketplace || {
    echo "failed to install VSCodium Dependencies"
    exit 1
}

echo "Installing Thunderbird dependencies"
yay -S --noconfirm --needed --combinedupgrade --batchinstall --noredownload thunderbird birdtray || {
    echo "failed to install Thunderbird dependencies"
    exit 1
}

echo "Enabling pcscd.socket"
sudo systemctl enable pcscd.socket && sudo systemctl start pcscd.socket || {
    echo "failed to enable pcscd.socket"
    exit 1
}

echo "Installing GPG / YubiKey dependencies"
yay -S --noconfirm --needed --combinedupgrade --batchinstall --noredownload gnupg pcsclite ccid hopenpgp-tools yubikey-agent yubikey-personalization yubikey-manager || {
    echo "failed to install GPG / YubiKey dependencies"
    exit 1
}

gnome_ssh=/etc/xdg/autostart/gnome-keyring-ssh.desktop
if [ -f "${gnome_ssh}" ]; then
    echo "Disabling GNOME Keyring SSH agent"
    (
        cat "${gnome_ssh}"
        echo Hidden=true
    ) >"$HOME"/.config/autostart/gnome-keyring-ssh.desktop || {
        echo "Failed to disable GNOME Keyring SSH agent"
        exit 1
    }
fi

cd "$BASE_PATH" || {
    echo "failed to cd to ${BASE_PATH}"
    exit 1
}

echo "Setting up user directory configs"
rm -f "$HOME"/.config/mimeapps.list

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

stow -v git || {
    echo "Failed to stow Git config"
    exit 1
}

stow -v vim || {
    echo "Failed to stow Vim config"
    exit 1
}
