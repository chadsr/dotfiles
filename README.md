# dotfiles
My dotfiles, managed with stow.

## Setup
```
git clone git@github.com:Chadsr/dotfiles.git
cd dotfiles
```

## Usage
Setup stow configs and also system configurations for the given system name:
```
./setup_all.sh [laptop|workstation]
```

...or manually for local configs only:

```
./stow_setup.sh (only needs running once)
stow <FOLDER_NAME>
```

*The silly stow-setup.sh script is because stow doesn't support environment variables in .stowrc, and I don't want to use absolute paths in this repo...*
