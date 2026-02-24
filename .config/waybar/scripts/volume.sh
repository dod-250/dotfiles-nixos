#!/usr/bin/env bash
# ── volume.sh ─────────────────────────────────────────────
# Description: Shows current audio volume with ASCII bar + tooltip
# Usage: Waybar `custom/volume` every 1s
# Dependencies: wpctl, awk, bc, seq, printf
# NixOS Compatible Version
# ───────────────────────────────────────────────────────────

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Try to get volume using different methods (NixOS compatibility)
get_volume() {
    if command_exists wpctl; then
        # Preferred method with wpctl (WirePlumber)
        vol_raw=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{ print $2 }')
        if [ -n "$vol_raw" ]; then
            echo "$vol_raw"
            return 0
        fi
    fi
    
    # Fallback to pactl (PulseAudio)
    if command_exists pactl; then
        vol_raw=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -Po '\d+(?=%)' | head -1)
        if [ -n "$vol_raw" ]; then
            echo "0.$vol_raw"
            return 0
        fi
    fi
    
    # Fallback to pamixer
    if command_exists pamixer; then
        vol_raw=$(pamixer --get-volume 2>/dev/null)
        if [ -n "$vol_raw" ]; then
            echo "0.$vol_raw"
            return 0
        fi
    fi
    
    # Default fallback
    echo "0.50"
}

# Get mute status
get_mute_status() {
    if command_exists wpctl; then
        wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -q MUTED && echo true || echo false
    elif command_exists pactl; then
        pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -q "yes" && echo true || echo false
    elif command_exists pamixer; then
        pamixer --get-mute 2>/dev/null | grep -q "true" && echo true || echo false
    else
        echo false
    fi
}

# Get sink description
get_sink_description() {
    if command_exists wpctl; then
        wpctl status 2>/dev/null | awk '/Sinks:/,/Sources:/' | grep '\*' | cut -d'.' -f2- | sed 's/^\s*//; s/\[.*//' | head -1
    elif command_exists pactl; then
        pactl info 2>/dev/null | grep "Default Sink:" | cut -d':' -f2 | sed 's/^\s*//'
    else
        echo "Unknown Device"
    fi
}

# Get raw volume and convert to int
vol_raw=$(get_volume)
if command_exists bc; then
    vol_int=$(echo "$vol_raw * 100" | bc 2>/dev/null | awk '{ print int($1) }')
else
    # Fallback without bc
    vol_int=$(awk "BEGIN {printf \"%.0f\", $vol_raw * 100}")
fi

# Ensure vol_int is a valid number
if ! [[ "$vol_int" =~ ^[0-9]+$ ]]; then
    vol_int=50
fi

# Clamp volume between 0 and 100
if [ "$vol_int" -gt 100 ]; then
    vol_int=100
elif [ "$vol_int" -lt 0 ]; then
    vol_int=0
fi

# Check mute status
is_muted=$(get_mute_status)

# Get default sink description (human-readable)
sink=$(get_sink_description)
if [ -z "$sink" ]; then
    sink="Unknown Device"
fi

# Icon logic with Nerd Font icons
if [ "$is_muted" = true ]; then
    icon="󰝟"  # nf-md-volume_off
    vol_int=0
elif [ "$vol_int" -eq 0 ]; then
    icon=""  # nf-md-volume_mute
elif [ "$vol_int" -lt 30 ]; then
    icon=""  # nf-md-volume_low
elif [ "$vol_int" -lt 70 ]; then
    icon=""  # nf-md-volume_medium
else
    icon=""  # nf-md-volume_high
fi

# ASCII bar
if [ "$vol_int" -eq 0 ]; then
    filled=0
else
    filled=$((vol_int / 10))
fi
empty=$((10 - filled))

# Build ASCII bar more safely
bar=""
pad=""
for ((i=0; i<filled; i++)); do
    bar+="█"
done
for ((i=0; i<empty; i++)); do
    pad+="░"
done
ascii_bar="[$bar$pad]"

# Color logic
if [ "$is_muted" = true ] || [ "$vol_int" -lt 10 ]; then
    fg="#ed8796" # red
elif [ "$vol_int" -lt 50 ]; then
    fg="#f5a97f" # peach
else
    fg="#a6da95" # green
fi

# Tooltip text
if [ "$is_muted" = true ]; then
    tooltip="Audio: Muted\\nOutput: $sink"
else
    tooltip="Audio: $vol_int%\\nOutput: $sink"
fi

# Final JSON output
echo "{\"text\":\"<span foreground='$fg'>$icon $ascii_bar $vol_int%</span>\",\"tooltip\":\"$tooltip\"}"