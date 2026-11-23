# shellcheck shell=bash

if [[ "$OSTYPE" == "darwin"* ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# environment.d once per login session
if [[ "$OSTYPE" == "linux-gnu"* && -x /usr/lib/systemd/user-environment-generators/30-systemd-environment-d-generator ]]; then
  while IFS='=' read -r _env_d_key _env_d_val; do
    [[ "$_env_d_key" == "PATH" ]] && continue
    export "$_env_d_key=$_env_d_val"
  done < <(/usr/lib/systemd/user-environment-generators/30-systemd-environment-d-generator)
  unset _env_d_key _env_d_val
fi

# session vars for non-graphical shells
if [[ "$OSTYPE" == "linux-gnu"* && -z "${WAYLAND_DISPLAY:-}" && -z "${DISPLAY:-}" ]]; then
  while IFS='=' read -r _sd_env_key _sd_env_val; do
    export "$_sd_env_key=$_sd_env_val"
  done < <(systemctl --user show-environment 2>/dev/null |
    grep -E '^(DISPLAY|WAYLAND_DISPLAY|SWAYSOCK|HYPRLAND_INSTANCE_SIGNATURE|XDG_CURRENT_DESKTOP|XDG_SESSION_TYPE)=')
  unset _sd_env_key _sd_env_val
fi
