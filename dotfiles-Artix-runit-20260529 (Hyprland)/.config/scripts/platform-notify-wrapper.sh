#!/bin/bash

export XDG_RUNTIME_DIR="/run/user/$(id -u)"

eval "$(dbus-launch --sh-syntax)"

/home/churrumais/.config/scripts/oerfil.sh