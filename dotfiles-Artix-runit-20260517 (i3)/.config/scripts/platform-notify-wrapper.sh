#!/bin/bash

export DISPLAY=:0
export XAUTHORITY="/home/churrumais/.Xauthority"

DBUS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$(pgrep -u churrumais i3 | head -n1)/environ | cut -d= -f2-)

export DBUS_SESSION_BUS_ADDRESS="$DBUS"

/home/churrumais/.config/scripts/oerfil.sh