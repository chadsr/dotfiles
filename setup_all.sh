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
    echo 'failed to update package databases'
    exit 1
}

git submodule update --init --recursive || {
    echo 'failed to update git submodules'
    exit 1
}

git submodule foreach --recursive git fetch || {
    echo 'failed to fetch git submodule updates'
    exit 1
}

cd "$GIT_SUBMODULES"/punk_theme || {
    echo "failed to cd to ${GIT_SUBMODULES}/punk_theme"
    exit 1
}
git rebase origin/Ultimate-Punk-Complete-Desktop || {
    echo "failed to rebase updates"
    exit 1
}

cd "$GIT_SUBMODULES"/sweet_theme || {
    echo "failed to cd to ${GIT_SUBMODULES}/sweet_theme"
    exit 1
}
git rebase origin/nova || {
    echo "failed to rebase updates"
    exit 1
}

cd "$GIT_SUBMODULES"/waybar-modules || {
    echo "failed to cd to ${GIT_SUBMODULES}/waybar-modules"
    exit 1
}
git rebase origin/master || {
    echo "failed to rebase updates"
    exit 1
}

cd "$BASE_PATH"/sway/.config/waybar/modules/waybar-crypto || {
    echo "failed to cd to ${BASE_PATH}/sway/.config/waybar/modules/waybar-crypto"
    exit 1
}
git rebase origin/master || {
    echo "failed to rebase updates"
    exit 1
}

cd "$BASE_PATH"/zsh/.oh-my-zsh/themes/powerlevel10k || {
    echo "failed to cd to ${BASE_PATH}/zsh/.oh-my-zsh/themes/powerlevel10k"
    exit 1
}
git rebase origin/master || {
    echo "failed to rebase updates"
    exit 1
}

cd "$BASE_PATH" || {
    echo "failed to cd back to ${BASE_PATH}"
    exit 1
}

echo "Copying common system configuration"
sudo cp -Rv "$SYSTEM_CONFIG"/common/* /

if [ "$1" == "laptop" ]; then
    echo "Checking if tpacpi-bat is installed"
    yay -S --needed --noredownload tpacpi-bat || {
        echo 'failed to install TLP packages'
        exit 1
    }
    echo "Copying laptop system configuration"
    sudo cp -Rv "$SYSTEM_CONFIG"/laptop/* /

    echo "Building and copying battery module for Waybar"
    cd "$GIT_SUBMODULES"/waybar-modules/battery || {
        echo "failed changing directory to ${GIT_SUBMODULES}/waybar-modules/battery"
        exit 1
    }
    make || {
        echo 'failed to make battery modules'
        exit 1
    }

    cp -v "$GIT_SUBMODULES"/waybar-modules/battery/wbm_battery0 "$BASE_PATH"/sway/.config/waybar/modules/battery || {
        echo "failed copying battery module to ${GIT_SUBMODULES}/waybar-modules/battery"
        exit 1
    }

    cp -v "$GIT_SUBMODULES"/waybar-modules/battery/wbm_battery1 "$BASE_PATH"/sway/.config/waybar/modules/battery || {
        echo "failed copying battery module to ${GIT_SUBMODULES}/waybar-modules/battery"
        exit 1
    }
elif [ "$1" == "workstation" ]; then
    sudo cp -Rv "$SYSTEM_CONFIG"/workstation/* /
else
    echo "$0: first argument must be 'laptop' or 'workstation'"
    exit 1
fi

echo "Copying themes from git repo to dotfiles locations"
cp -Ruv "$GIT_SUBMODULES"/punk_theme/PUNK-Cyan-Cursor "$BASE_PATH"/sway/.icons/ || {
    echo 'failed copying PUNK-Cyan-Cursor to sway'
    exit 1
}
cp -Ruv "$GIT_SUBMODULES"/punk_theme/Ultimate-Punk-Suru++ "$BASE_PATH"/sway/.icons/ || {
    echo 'failed copying Ultimate-Punk-Suru++ to sway'
    exit 1
}
cp -Ruv "$GIT_SUBMODULES"/punk_theme/Ultimate-PUNK-Suru "$BASE_PATH"/sway/.icons/ || {
    echo 'failed copying Ultimate-PUNK-Suru to sway'
    exit 1
}
cp -Ruv "$GIT_SUBMODULES"/sweet_theme "$BASE_PATH"/sway/.themes/ || {
    echo 'failed copying sweet theme to sway'
    exit 1
}

echo "Checking for ZSH dependencies to install"
nohup sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >/dev/null 2>&1 &# This will fail if already installed, so don't bother checking

yay -S --needed --noredownload zsh thefuck || {
    echo 'failed to install ZSH config dependencies'
    exit 1
}
echo "Checking for Sway dependencies to install"
yay -S --needed --combinedupgrade --batchinstall --noredownload sway gdk-pixbuf2 ranger pulseaudio-ctl shotwell light waybar libappindicator-gtk2 libappindicator-gtk3 dex rofi otf-font-awesome python python-requests networkmanager-dmenu slurp grim swayshot swaylock-blur-git mako redshift-wlr-gamma-control-git gtk-engines alacritty || {
    echo 'failed to install Sway dependencies'
    exit 1
}

echo "Checking or Thunderbird dependencies"
yay -S --needed --noredownload thunderbird birdtray || {
    echo 'failed to install Thunderbird dependencies'
    exit 1
}

echo "Checking for Cadence/Jack dependencies to install"
yay -S --needed --noredownload jack2 pulseaudio-alsa pulseaudio-jack pavucontrol cadence || {
    echo 'failed to install audio dependencies'
    exit 1
}

cd "$BASE_PATH" || {
    echo "failed to cd to ${BASE_PATH}"
    exit 1
}

echo "Setting up user directory configs"
mkdir "$HOME"/.config/pulse # Make this if it doesn't exist, so PulseAudio doesn't complain about there being too many levels of symbolic links from stow
stow -v zsh
stow -v cadence
stow -v sway
stow -v git

echo "Setup finished successfully!"
exit 0
