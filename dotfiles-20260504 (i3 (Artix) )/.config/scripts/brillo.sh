#!/bin/bash
# Script para controlar el brillo + notificación con Dunst
# Requiere: brightnessctl y dunst

# Comprobar si brightnessctl está instalado
if ! command -v brightnessctl &>/dev/null; then
    echo "❌ brightnessctl no está instalado."
    exit 1
fi

# Cambiar brillo según argumento
case "$1" in
    up)
        brightnessctl set +5% > /dev/null
        ;;
    down)
        brightnessctl set 5%- > /dev/null
        ;;
    *)
        echo "Uso: $0 {up|down}"
        exit 1
        ;;
esac

# Obtener el brillo actual (en porcentaje)
BRIGHTNESS=$(brightnessctl get)
MAX=$(brightnessctl max)
PERCENT=$(( 100 * BRIGHTNESS / MAX ))

# Elegir icono según nivel de brillo
if [ "$PERCENT" -lt 30 ]; then
    ICON="display-brightness-low"
elif [ "$PERCENT" -lt 70 ]; then
    ICON="display-brightness-medium"
else
    ICON="display-brightness-high"
fi

# Enviar notificación reemplazable
notify-send -a "Brillo" -i "$ICON" "Brillo: ${PERCENT}%" \
    -h int:value:$PERCENT -h string:synchronous:brightness -u normal
