#!/bin/bash
# Requiere: greenclip, rofi, xclip

# Asegurar que greenclip esté corriendo
pgrep -x greenclip >/dev/null || greenclip daemon &

# Mostrar historial en rofi
selection=$(greenclip print | rofi -dmenu -p "Historial" -theme ~/.config/rofi/launchers/type-2/style-1.rasi)

# Copiar la selección al portapapeles
if [ -n "$selection" ]; then
    echo -n "$selection" | xclip -selection clipboard
fi
