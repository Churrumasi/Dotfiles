#!/bin/bash
# Script para controlar volumen en PipeWire + Dunst (LXDE)
# Usa pactl y muestra una notificación cada vez que cambias el volumen.

SINK=$(pactl get-default-sink)

case "$1" in
    up)
        pactl set-sink-volume "$SINK" +5%
        ;;
    down)
        pactl set-sink-volume "$SINK" -5%
        ;;
    mute)
        pactl set-sink-mute "$SINK" toggle
        ;;
    *)
        echo "Uso: $0 {up|down|mute}"
        exit 1
        ;;
esac

# Obtener volumen y mute
VOL=$(pactl get-sink-volume "$SINK" | grep -oP '\d+%' | head -1 | tr -d '%')
MUTE=$(pactl get-sink-mute "$SINK" | awk '{print $2}')

# Elegir icono según nivel
if [ "$MUTE" = "yes" ]; then
    ICON="audio-volume-muted"
    MSG="Silenciado"
else
    if [ "$VOL" -lt 30 ]; then
        ICON="audio-volume-low"
    elif [ "$VOL" -lt 70 ]; then
        ICON="audio-volume-medium"
    else
        ICON="audio-volume-high"
    fi
    MSG="Volumen: ${VOL}%"
fi

# Notificación persistente (se reemplaza en cada cambio)
notify-send -a "Volumen" -i "$ICON" "$MSG" \
    -h int:value:$VOL -h string:synchronous:volume -u normal
