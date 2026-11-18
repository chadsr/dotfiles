#!/usr/bin/env bash

# Shared helpers sourced by setup.sh, setup-macos.sh and store-secrets.sh

exit_setup() {
  rv=$?
  printf "\n\nExiting setup (status %s)...\n" "$rv"
  exit "$rv"
}

prompt_exit() {
  read -rp "$1 Continue or Abort? (y/N)" answer
  case ${answer:0:1} in
  y | Y)
    return 0
    ;;
  *)
    exit_setup 0
    ;;
  esac
}

cd_dotfiles() {
  # shellcheck disable=SC2154
  if [[ -n ${DOTFILES+x} ]] && [[ "$base_path" != "$DOTFILES" ]]; then
    echo "Changing directory to '${DOTFILES}'"
    cd "$DOTFILES" || exit
  fi
}

rmrf() {
  rm -rf "${1}" || {
    echo "failed to recursively remove ${1}"
    return 1
  }
}

symlink() {
  if [[ -e "${2}" ]]; then
    if [[ ! -L "${2}" ]]; then
      echo "${2} already exists and is an irregular type. Check manually whether this is safe to replace with ${1}."
      return 1
    fi

    echo "Removing existing symlink at ${2}"
    rmrf "${2}" || {
      echo "failed to remove old symlink: ${2}"
      return 1
    }
  fi

  if [[ "$OSTYPE" == darwin* ]]; then
    # BSD ln does not support relative symlinks
    ln -s "${1}" "${2}" || {
      echo "failed to symlink: ${1} to ${2}"
      return 1
    }
  else
    # Stow only supports relative symlinks
    ln -rs "${1}" "${2}" || {
      echo "failed to symlink: ${1} to ${2}"
      return 1
    }
  fi
}

install_packages() {
  # shellcheck disable=SC2154
  case "$package_manager" in
  */brew)
    "$package_manager" install -- "${@}" || {
      echo "failed to install:"
      echo "${@}"
      return 1
    }
    ;;
  */yay)
    "$package_manager" -S --noconfirm --needed --noredownload -- "${@}" || {
      echo "failed to install:"
      echo "${@}"
      return 1
    }
    ;;
  *)
    echo "unsupported package manager: ${package_manager}"
    return 1
    ;;
  esac
}

remove_package() {
  case "$package_manager" in
  */brew)
    if "$package_manager" list --formula "${1}" >/dev/null; then
      "$package_manager" uninstall "${1}" >/dev/null || {
        :
      }
    fi
    ;;
  */yay)
    if "$package_manager" -Qi "${1}" >/dev/null; then
      "$package_manager" -R --noconfirm -- "${1}" >/dev/null || {
        :
      }
    fi
    ;;
  *)
    echo "unsupported package manager: ${package_manager}"
    return 1
    ;;
  esac
}

diff_files() {
  if [[ ! -f "$1" ]] && [[ ! -L "$1" ]]; then
    echo "file ${1} does not exist"
    return 1
  fi
  if [[ ! -f "$2" ]] && [[ ! -L "$2" ]]; then
    echo "file ${2} does not exist"
    return 1
  fi

  if (cmp -s "$1" "$2"); then
    # If they are identical, then return
    return 0
  else
    # shellcheck disable=SC2154
    "${diff_command[@]}" "$1" "$2" || {
      echo "${diff_command[0]} on ${1} <-> ${2}' exited with error"
      return 1
    }
  fi
}

# gpg is used directly throughout setup; decrypt diffs prevent unwanted changes going unnoticed
gpg_decrypt_file() {
  if [[ ! -f "$1" ]] && [[ ! -L "$1" ]]; then
    echo "input file ${1} does not exist"
    return 1
  fi

  local input_file_path="${1}"
  local output_file_path="${2}"
  local output_filename
  output_filename=$(basename "$output_file_path")

  # shellcheck disable=SC2154
  local tmp_output_file_path="${tmp_path}/${output_filename}"

  echo "Decrypting ${input_file_path} to ${tmp_output_file_path}"

  # shellcheck disable=SC2154
  gpg --quiet --no-verbose --local-user "$gpg_encryption_subkey" --armor --decrypt --yes --output "$tmp_output_file_path" "$input_file_path" >/dev/null || {
    echo "failed to decrypt file ${input_file_path} to ${tmp_output_file_path}"
    return 1
  }

  # if the file to replace already exists, perform a diff to check for changes
  if [[ -f "$output_file_path" ]]; then
    diff_files "$output_file_path" "$tmp_output_file_path"
  fi

  cp -f "$tmp_output_file_path" "$output_file_path" || {
    echo "failed to copy '${tmp_output_file_path}' to '${output_file_path}'"
    return 1
  }
}

gpg_encrypt_file() {
  if [[ ! -f "$1" ]] && [[ ! -L "$1" ]]; then
    echo "input file ${1} does not exist"
    return 1
  fi

  local input_file_path="$1"
  local output_file_path="$2"
  local output_filename
  output_filename=$(basename "$output_file_path")
  local tmp_output_file_path="${tmp_path}/${output_filename}"
  local input_file_existing_equal=false

  # if the file to replace already exists, perform a diff to check for changes
  if [[ -f "$output_file_path" ]]; then
    tmp_output_file_path_current="$tmp_output_file_path".current
    gpg --quiet --no-verbose --local-user "$gpg_encryption_subkey" --armor --decrypt --yes --output "$tmp_output_file_path_current" "$output_file_path" >/dev/null || {
      echo "failed to decrypt file ${output_file_path} to ${tmp_output_file_path_current}"
      return 1
    }

    if (cmp -s "$tmp_output_file_path_current" "$input_file_path"); then
      input_file_existing_equal=true
    else
      diff_files "$tmp_output_file_path_current" "$input_file_path"
    fi
  fi

  if [[ $input_file_existing_equal == true ]]; then
    printf "%s <-> %s are equal. skipping encryption.\n" "$input_file_path" "$output_file_path"
  else
    gpg --quiet --no-verbose --local-user "$gpg_encryption_subkey" --recipient "$gpg_encryption_subkey" --armor --sign --yes --output "$tmp_output_file_path" --encrypt "$input_file_path" >/dev/null || {
      echo "failed to encrypt file ${input_file_path} to ${tmp_output_file_path}"
      return 1
    }

    cp -f "$tmp_output_file_path" "$output_file_path" || {
      echo "failed to copy '${tmp_output_file_path}' to '${output_file_path}'"
      return 1
    }

    printf "%s -> %s\n" "$input_file_path" "$output_file_path"
  fi
}

line_exists() {
  case $(
    grep -Fxq "${1}" "${2}" >/dev/null
    echo $?
  ) in
  0)
    # Found
    return 0
    ;;
  1)
    # Not found
    return 1
    ;;
  *)
    exit 1
    ;;
  esac
}

string_exists() {
  case $(
    grep -Fq "${1}" "${2}" >/dev/null
    echo $?
  ) in
  0)
    # Found
    return 0
    ;;
  1)
    # Not found
    return 1
    ;;
  *)
    exit 1
    ;;
  esac
}

rm_if_not_stowed() {
  if [[ -L "${1}" ]]; then
    local symlink_path
    symlink_path=$(readlink -f "${1}")
    if [[ $symlink_path == *"$base_path"* ]]; then
      return 0
    fi
  fi

  rm -rfv "${1}" || {
    echo "failed to remove conflict path ${1}"
    return 1
  }
}

rsync_system_config() {
  # shellcheck disable=SC2154
  local system_config_full_path="$system_config_path"/"${1}"
  local rsync_bin="rsync"
  local rsync_chown="root:root"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    rsync_bin="/opt/homebrew/bin/rsync"
    rsync_chown="root:wheel"
  fi

  if [[ ! -d "$system_config_full_path" ]]; then
    echo "The provided path '${system_config_full_path}' does not exist!"
    return 1
  fi

  sudo "$rsync_bin" --chown="$rsync_chown" --open-noatime --exclude='.gitkeep' --progress -ruacvLKO -- "$system_config_full_path"/* / || {
    echo "failed to rsync system config from ${system_config_full_path} to root filesystem"
    return 1
  }
}

stow_config() {
  stow -v "$1" || {
    echo "Failed to stow ${1} config"
    exit 1
  }
}

import_gpg_pubkey() {
  # If our primary GPG key is not yet imported, import it
  # shellcheck disable=SC2154
  if [[ ! $(gpg --list-keys "$gpg_primary_key") ]]; then
    gpg --import "$data_path"/gpg/"${gpg_primary_key#0x}".asc || {
      echo "failed to import GPG pubkey"
      exit 1
    }

    gpg --tofu-policy good "$gpg_primary_key" || {
      echo "failed to set gpg tofu policy"
      exit 1
    }
  fi
}

update_submodules() {
  git submodule update --init --recursive --remote --progress || {
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
}

fix_catppuccin_bat_theme() {
  # Fix for spacing breaking the space delimited tuples
  # shellcheck disable=SC2154
  mv "$git_submodule_path"/catppuccin-bat/themes/Catppuccin\ Mocha.tmTheme "$git_submodule_path"/catppuccin-bat/themes/Catppuccin-Mocha.tmTheme || {
    echo "failed to move catppuccin-bat theme"
    exit 1
  }
}

pull_ollama_models() {
  for ollama_model in "${@}"; do
    ollama pull "$ollama_model" || {
      echo "failed to install ${ollama_model}"
      exit 1
    }
  done
}
