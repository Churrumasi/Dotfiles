#!/bin/bash

# Ruta donde se guardará la grabación
DIR="$HOME/Videos"
FILENAME="grabacion_$(date +%Y-%m-%d_%H-%M-%S).mp4"
FULLPATH="$DIR/$FILENAME"

# Crear el directorio si no existe
if [ ! -d "$DIR" ]; then
    mkdir -p "$DIR"
    notify-send "Carpeta 'Videos' creada"
fi

# Detectar si wf-recorder ya está corriendo
PID=$(pgrep wf-recorder)

if [ -z "$PID" ]; then
    # No está corriendo, iniciar grabación
    wf-recorder -f "$FULLPATH" &
    notify-send "Grabación iniciada" "Archivo: $FILENAME"
else
    # wf-recorder está corriendo, detenerlo
    kill "$PID"
    notify-send "✅ Grabación detenida"
fi

