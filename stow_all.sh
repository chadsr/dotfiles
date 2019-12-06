#!/usr/bin/env bash

prompt () {
    read -p "$1 Continue (y/n)? " answer
    case ${answer:0:1} in
        y|Y )
            return
        ;;
        * )
            exit 0
        ;;
    esac
}

./stow_setup.sh

if [ $1 == "laptop" ] ; then
    prompt "This will remove existing system settings"
    echo "Checking if tpacpi-bat is installed"
    yay -S --needed tpacpi-bat
    sudo rm -rf /etc/default/tlp
    sudo stow -v --target="/" laptop_system
elif [ $1 == "workstation" ] ; then
    prompt "This will remove existing system settings"
    sudo rm -rf /etc/default/tlp
    sudo stow -v --target="/" workstation_system
else 
    echo "$0: first argument must be 'laptop' or 'workstation'"
    exit 1
fi

echo "Getting git submodules"
git submodule update --init --recursive
cd git_themes/PUNK
git checkout Ultimate-Punk-Complete-Desktop
cd ../sweet_dark
git checkout nova
cd ../../

echo "Copying themes from git repo to dotfiles locations"
cp -Rv ./git_themes/PUNK/PUNK-Cyan-Cursor ./sway/.icons/
cp -Rv ./git_themes/PUNK/Ultimate-Punk-Suru++ ./sway/.icons/
cp -Rv ./git_themes/sweet_dark ./sway/.themes/

echo "Checking for ZSH dependencies to install"
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"x
yay -S --needed zsh thefuck

echo "Checking for Sway dependencies to install"
yay -S --needed sway light waybar libappindicator-gtk3 dex rofi otf-font-awesome python python-requests networkmanager-dmenu slurp grim swayshot swaylock-blur-git mako redshift-wlr-gamma-control-git gtk-engines alacritty

echo "Setting up user directory configs"
stow -v firefox
stow -v zsh
stow -v sway
stow -v git

exit 0