# dotfiles
My dotfiles, managed with stow.

## Setup
```
git clone git@github.com:Chadsr/dotfiles.git
cd dotfiles
./stow-setup.sh
```

**The silly stow-setup.sh script is because stow doesn't support environment variables in .stowrc, and I don't want to use absolute paths in this repo...**

## Usage
```
stow <FOLDER_NAME>
```
