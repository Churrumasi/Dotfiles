#!/bin/bash
# Wallpaper animado con gifview + xwinwrap

# mata instancias previas
killall xwinwrap gifview 2>/dev/null

# espera a que picom y pcmanfm terminen de cargar
sleep 0.5

# ejecuta el wallpaper
#xwinwrap -ov -g 1920x1080+0+0 -- mpv --no-audio --loop --no-osd-bar --wid=%WID ~/.config/fondo/fondo.mp4 &
xwinwrap -ov -g 1920x1080+0+0 -- \
mpv --no-audio --loop --no-osc --osd-level=0 --no-osd-bar \
--really-quiet --no-input-default-bindings --wid=%WID \
~/.config/fondo/fondo.mp4 &
