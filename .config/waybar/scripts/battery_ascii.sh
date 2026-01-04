#!/usr/bin/env bash

# Waybar ASCII battery module - NixOS Compatible

# Configuration
BATTERY_PATH="/sys/class/power_supply/BAT0"
BAR_LENGTH=10
FULL_CHAR="█"
EMPTY_CHAR="░"

# Battery
if [ ! -d "$BATTERY_PATH" ]; then
    echo '{"text": "No Battery", "class": "no-battery"}'
    exit 0
fi

# Battery informations
CAPACITY=$(cat "$BATTERY_PATH/capacity" 2>/dev/null || echo "0")
STATUS=$(cat "$BATTERY_PATH/status" 2>/dev/null || echo "Unknown")

# Calculer le nombre de caractères pleins
FILLED_CHARS=$((CAPACITY * BAR_LENGTH / 100))
EMPTY_CHARS=$((BAR_LENGTH - FILLED_CHARS))

# Build ASCII bar
BAR=""
for ((i=0; i<FILLED_CHARS; i++)); do
    BAR+="$FULL_CHAR"
done
for ((i=0; i<EMPTY_CHARS; i++)); do
    BAR+="$EMPTY_CHAR"
done

# Icon and status
case "$STATUS" in
    "Charging")
        if [ "$CAPACITY" -ge 90 ]; then
            ICON="󰂅"  # nf-md-battery_charging_100
        elif [ "$CAPACITY" -ge 80 ]; then
            ICON="󰂋"  # nf-md-battery_charging_90
        elif [ "$CAPACITY" -ge 70 ]; then
            ICON="󰂊"  # nf-md-battery_charging_80
        elif [ "$CAPACITY" -ge 60 ]; then
            ICON="󰢞"  # nf-md-battery_charging_70
        elif [ "$CAPACITY" -ge 50 ]; then
            ICON="󰂉"  # nf-md-battery_charging_60
        elif [ "$CAPACITY" -ge 40 ]; then
            ICON="󰢝"  # nf-md-battery_charging_50
        elif [ "$CAPACITY" -ge 30 ]; then
            ICON="󰂈"  # nf-md-battery_charging_40
        elif [ "$CAPACITY" -ge 20 ]; then
            ICON="󰂇"  # nf-md-battery_charging_30
        elif [ "$CAPACITY" -ge 10 ]; then
            ICON="󰂆"  # nf-md-battery_charging_20
        else
            ICON="󰢜"  # nf-md-battery_charging_10
        fi
        CLASS="charging"
        ;;
    "Full")
        ICON="󰁹"  # nf-md-battery
        CLASS="full"
        ;;
    "Discharging")
        if [ "$CAPACITY" -ge 90 ]; then
            ICON="󰁹"  # nf-md-battery_90
            CLASS="normal"
        elif [ "$CAPACITY" -ge 80 ]; then
            ICON="󰂂"  # nf-md-battery_80
            CLASS="normal"
        elif [ "$CAPACITY" -ge 70 ]; then
            ICON="󰂁"  # nf-md-battery_70
            CLASS="normal"
        elif [ "$CAPACITY" -ge 60 ]; then
            ICON="󰂀"  # nf-md-battery_60
            CLASS="normal"
        elif [ "$CAPACITY" -ge 50 ]; then
            ICON="󰁿"  # nf-md-battery_50
            CLASS="normal"
        elif [ "$CAPACITY" -ge 40 ]; then
            ICON="󰁾"  # nf-md-battery_40
            CLASS="normal"
        elif [ "$CAPACITY" -ge 30 ]; then
            ICON="󰁽"  # nf-md-battery_30
            CLASS="low"
        elif [ "$CAPACITY" -ge 20 ]; then
            ICON="󰁼"  # nf-md-battery_20
            CLASS="low"
        elif [ "$CAPACITY" -ge 10 ]; then
            ICON="󰁻"  # nf-md-battery_10
            CLASS="critical"
        else
            ICON="󰁺"  # nf-md-battery_alert
            CLASS="critical"
        fi
        ;;
    *)
        ICON=""  # nf-md-battery_unknown
        CLASS="unknown"
        ;;
esac

TEXT="$ICON [$BAR] $CAPACITY%"

echo "{\"text\": \"$TEXT\", \"percentage\": $CAPACITY, \"class\": \"$CLASS\", \"tooltip\": \"Battery: $CAPACITY% ($STATUS)\"}"