#!/bin/bash
# Script para controlar volumen en PipeWire + Dunst (LXDE)
# Usa pactl y muestra una notificación cada vez que cambias el volumen.
# Está limitado a 0%..100%.

SINK=$(pactl get-default-sink)

# Obtener volumen actual (primer canal) como entero; si falla, usar 0
VOL_BEFORE=$(pactl get-sink-volume "$SINK" | grep -oP '\d+%' | head -1 | tr -d '%' )
VOL_BEFORE=${VOL_BEFORE:-0}

case "$1" in
    up)
        NEW=$((VOL_BEFORE + 5))
        if [ "$NEW" -gt 100 ]; then
            NEW=100
        fi
        pactl set-sink-volume "$SINK" "${NEW}%"
        ;;
    down)
        NEW=$((VOL_BEFORE - 5))
        if [ "$NEW" -lt 0 ]; then
            NEW=0
        fi
        pactl set-sink-volume "$SINK" "${NEW}%"
        ;;
    mute)
        pactl set-sink-mute "$SINK" toggle
        ;;
    *)
        echo "Uso: $0 {up|down|mute}"
        exit 1
        ;;
esac

# Obtener volumen y mute (después del cambio)
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
