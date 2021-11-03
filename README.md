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
stow -d ~/ stow
stow <FOLDER_NAME>
```