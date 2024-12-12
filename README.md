# dotfiles

[![Lint](https://github.com/chadsr/dotfiles/actions/workflows/lint.yml/badge.svg)](https://github.com/chadsr/dotfiles/actions/workflows/lint.yml)

My dotfiles, managed with [`stow`](https://www.gnu.org/software/stow/).

![Hyprland](.github/assets/hypr.png)


## Setup

```shell
git clone git@github.com:chadsr/dotfiles.git && cd dotfiles/
```

## Usage

### Per-Directory

```bash
stow -t ~/ stow
stow <FOLDER_NAME>
```

### Scripts

**Important:** *Don't run these scripts without modifications if your're not me, or haven't (yet) stolen my private keys.*

#### Automated Setup

`setup.sh` symlinks all stow directories to `$HOME`, sets up `gnupg` and installs system settings and other configurations. The script is designed to have a completely fresh Arch Linux system configured with minimal interaction.

```bash
./setup.sh
```

#### Backup

 `store-secrets.sh` encrypts various configs and stores them as ASCII-Armoured `gpg` file outputs. `setup.sh` handles the decryption and checks (such as interactive diffs) for these files.

```bash
./store-secrets.sh
```
