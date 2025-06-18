#!/usr/bin/env bash

folder="$HOME/Imagenes/Capturas de pantalla"
mkdir -p "$folder"
filename="$folder/Captura de pantalla -$(date +%Y-%m-%d_%H-%M-%S).png"

# Captura área seleccionada
slurp | grim -g - "$filename"

# Copiar al portapapeles
cat "$filename" | wl-copy --type image/png

# Notificación
notify-send "Captura guardada y copiada al portapapeles" "$filename"

