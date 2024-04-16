#!/usr/bin/env bash

laptop_hostname="thinky"
desktop_hostname="shifty"
current_hostname=$(hostname)

if [[ "$current_hostname" == "$desktop_hostname" ]]; then
    cpu_dir="$(dirname "$(grep -l k10temp /sys/class/hwmon/hwmon*/name)")"
    gpu_dir="$(dirname "$(grep -l amdgpu /sys/class/hwmon/hwmon*/name)")"
elif [[ "$current_hostname" == "$laptop_hostname" ]]; then
    cpu_dir="$(dirname "$(grep -l coretemp /sys/class/hwmon/hwmon*/name)")"
    gpu_dir="$cpu_dir"
fi

ln -sf "$cpu_dir"/temp1_input /tmp/cpu_temperature
ln -sf "$gpu_dir"/temp1_input /tmp/gpu_temperature
