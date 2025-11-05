#!/usr/bin/env bash

# Toggle Bluetooth on/off using rfkill.

if rfkill list bluetooth | grep -q "Soft blocked: yes"; then
    rfkill unblock bluetooth
else
    rfkill block bluetooth
fi

