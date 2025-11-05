#!/usr/bin/env bash

# Description: Shows current brightness with ASCII bar + tooltip

# Get brightness percentage
brightness=$(brightnessctl get)
max_brightness=$(brightnessctl max)
percent=$((brightness * 100 / max_brightness))

# Build ASCII bar
filled=$((percent / 10))
empty=$((10 - filled))
bar=$(printf '█%.0s' $(seq 1 $filled))
pad=$(printf '░%.0s' $(seq 1 $empty))
ascii_bar="[$bar$pad]"

# Icon
icon="󰛨"

# Color thresholds
if [ "$percent" -lt 20 ]; then
    fg="#ed8796"  # red
elif [ "$percent" -lt 55 ]; then
    fg="#f5a97f"  # peacg
else
    fg="#a6da95"  # green
fi

# Device name (first column from brightnessctl --machine-readable)
device=$(brightnessctl --machine-readable | awk -F, 'NR==1 {print $1}')

# Tooltip text
tooltip="Brightness: $percent%\nDevice: $device"

# JSON output
echo "{\"text\":\"<span foreground='$fg'>$icon $ascii_bar $percent%</span>\",\"tooltip\":\"$tooltip\"}"

