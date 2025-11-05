#!/usr/bin/env bash

#  Rofi Power Menu

rofi_command="rofi -dmenu -p Power"

options="Shutdown\nReboot\nLogout\nSuspend\nLock"

chosen="$(echo -e "$options" | $rofi_command)"
case $chosen in
    Shutdown) systemctl poweroff ;;
    Reboot) systemctl reboot ;;
    Logout) hyprctl dispatch exit ;;
    Suspend) systemctl suspend ;;
    Lock) ~/.config/hyprlock/lock.sh ;;
esac

