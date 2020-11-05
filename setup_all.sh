#!/usr/bin/env bash

BASE_PATH=$PWD
SYSTEM_CONFIG="$BASE_PATH"/system
GIT_SUBMODULES="$BASE_PATH"/.git_submodules

prompt() {
    read -rp "$1 Continue (y/n)? " answer
    case ${answer:0:1} in
    y | Y)
        return
        ;;
    *)
        exit 0
        ;;
    esac
}

prompt "This script will remove existing system settings"

"$BASE_PATH"/stow_setup.sh

echo "Updating package databases"
yay -Syy || {
    echo "failed to update package databases"
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

cd "$GIT_SUBMODULES"/punk_theme || {
    echo "failed to cd to ${GIT_SUBMODULES}/punk_theme"
    exit 1
}
git checkout --force origin/Ultimate-Punk-Complete-Desktop || {
    echo "failed to checkout updates"
    exit 1
}

# cd "$GIT_SUBMODULES"/sweet_theme || {
#     echo "failed to cd to ${GIT_SUBMODULES}/sweet_theme"
#     exit 1
# }
# git checkout --force origin/nova || {
#     echo "failed to checkout updates"
#     exit 1
# }

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

if [ "$1" == "laptop" ]; then
    echo "Checking if tpacpi-bat is installed"
    yay -S --noconfirm --needed --noredownload tpacpi-bat || {
        echo "failed to install TLP packages"
        exit 1
    }

    echo "Checking if python-validity is installed"
    yay -S --noconfirm --needed --noredownload python-validity || {
        echo "failed to install python-validity"
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

    echo "Building and copying battery module for Waybar"
    cd "$GIT_SUBMODULES"/waybar-modules/battery || {
        echo "failed changing directory to ${GIT_SUBMODULES}/waybar-modules/battery"
        exit 1
    }
    make || {
        echo "failed to make battery modules"
        exit 1
    }

    mv -v "$GIT_SUBMODULES"/waybar-modules/battery/wbm_battery0 "$BASE_PATH"/sway/.config/waybar/modules/battery || {
        echo "failed moving battery module to ${GIT_SUBMODULES}/waybar-modules/battery"
        exit 1
    }

    mv -v "$GIT_SUBMODULES"/waybar-modules/battery/wbm_battery1 "$BASE_PATH"/sway/.config/waybar/modules/battery || {
        echo "failed moving battery module to ${GIT_SUBMODULES}/waybar-modules/battery"
        exit 1
    }
elif [ "$1" == "workstation" ]; then
    sudo rsync -av "$SYSTEM_CONFIG"/workstation / || {
        echo "failed copying workstation configuration"
        exit 1
    }
else
    echo "$0: first argument must be <laptop|workstation>"
    exit 1
fi

echo "Copying themes from git repo to dotfiles locations"
rsync -av "$GIT_SUBMODULES"/punk_theme/Ultimate-PUNK-Cyan-Cursor "$BASE_PATH"/sway/.icons || {
    echo "failed copying Ultimate-PUNK-Cyan-Cursor to sway"
    exit 1
}
rsync -av "$GIT_SUBMODULES"/punk_theme/Ultimate-Punk-Suru++ "$BASE_PATH"/sway/.icons || {
    echo "failed copying Ultimate-Punk-Suru++ to sway"
    exit 1
}
rsync -av "$GIT_SUBMODULES"/Cyberpunk-Neon/gtk "$BASE_PATH"/sway/.themes || {
    echo "failed copying sweet theme to sway"
    exit 1
}
# rsync -av "$GIT_SUBMODULES"/sweet_theme "$BASE_PATH"/sway/.themes || {
#     echo "failed copying sweet theme to sway"
#     exit 1
# }

echo "Checking for ZSH dependencies to install"
nohup sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >/dev/null 2>&1 &# This will fail if already installed, so don"t bother checking

yay -S --noconfirm --needed --combinedupgrade --batchinstall --noredownload zsh thefuck ttf-meslo-nerd-font-powerlevel10k || {
    echo "failed to install ZSH config dependencies"
    exit 1
}

echo "Checking for old Sway dependencies to remove"
yay -R --noconfirm pipewire-pulseaudio pipewire-pulseaudio-git

echo "Checking for Sway dependencies to install"
yay -S --noconfirm --needed --combinedupgrade --batchinstall --noredownload sway kanshi pulseaudio-alsa libopenaptx-git xdg-desktop-portal xdg-desktop-portal-wlr pavucontrol qt5-base qt5-wayland wayland-protocols pipewire wdisplays-git gdk-pixbuf2 ranger pulseaudio-ctl shotwell light waybar-git libappindicator-gtk2 libappindicator-gtk3 dex rofi otf-font-awesome nerd-fonts-hack python python-requests networkmanager-dmenu slurp grim swayshot swaylock-blur-git mako redshift-wayland-git gtk-engines alacritty udiskie wayvnc ansiweather qgnomeplatform || {
    echo "failed to install Sway dependencies"
    exit 1
}

# echo "Installing nerd-fonts-complete"
# cd "$BASE_PATH" || {
#     echo "failed to cd back to ${BASE_PATH}"
#     exit 1
# }
# yay --getpkgbuild nerd-fonts-complete || {
#     echo "failed to get pkgbuild for nerd-fonts-complete"
#     exit 1
# }
# cd nerd-fonts-complete/ || {
#     echo "failed to cd to nerd-fonts-complete build directory"
#     exit 1
# }
# wget -c -O nerd-fonts-2.1.0.tar.gz https://github.com/ryanoasis/nerd-fonts/archive/v2.1.0.tar.gz || {
#     echo "failed to wget nerd-fonts-complete"
#     exit 1
# }
# makepkg -sci BUILDDIR=. || {
#     echo "failed to makepkg nerd-fonts-complete"
#     exit 1
# }
# cd "$BASE_PATH" || {
#     echo "failed to cd back to ${BASE_PATH}"
#     exit 1
# }
# rm -rfv nerd-fonts-complete/ || {
#     echo "failed to clean up nerd-fonts-complete"
#     exit 1
# }

echo "Installing obs"
yay -S --noconfirm --needed --combinedupgrade --batchinstall --noredownload obs-studio-wayland wlrobs-hg obs-xdg-portal-git || {
    echo "failed to install git flow"
    exit 1
}

echo "Installing VSCodium fork"
yay -S --noconfirm --needed --noredownload vscodium-bin || {
    echo "failed to install VSCodium"
    exit 1
}

echo "Installing ungoogled chromium (ozone)"
yay -S --noconfirm --needed --noredownload ungoogled-chromium-ozone || {
    echo "failed to install ungoogled chromium (ozone)"
    exit 1
}

echo "Installing git flow"
yay -S --noconfirm --needed --combinedupgrade --batchinstall --noredownload gitflow-avh || {
    echo "failed to install git flow"
    exit 1
}

echo "Checking or Thunderbird dependencies"
yay -S --noconfirm --needed --combinedupgrade --batchinstall --noredownload thunderbird birdtray || {
    echo "failed to install Thunderbird dependencies"
    exit 1
}

cd "$BASE_PATH" || {
    echo "failed to cd to ${BASE_PATH}"
    exit 1
}

echo "Setting up user directory configs"
rm -f "$HOME"/.config/mimeapps.list
stow -v zsh
stow -v sway
stow -v git

prompt "Install JACK audio configuration"
echo "Checking for Cadence/Jack dependencies to install"
yay -S --noconfirm --needed --combinedupgrade --batchinstall --noredownload jack2 pipewire-jack pulseaudio-jack cadence libffado || {
    echo "failed to install audio dependencies"
    exit 1
}

mkdir "$HOME"/.pulse # Make this if it doesn"t exist, so PulseAudio doesn"t complain about there being too many levels of symbolic links from stow
stow -v jack
