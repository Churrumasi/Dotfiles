#!/bin/bash
# Script de captura de pantalla para LXDE (X11)
# Requiere: scrot, xclip, notify-send

# Carpeta donde guardar las capturas
folder="$HOME/Imágenes/Capturas de pantalla"
mkdir -p "$folder"

# Nombre del archivo
filename="$folder/Captura de pantalla -$(date +%Y-%m-%d_%H-%M-%S).png"

# Verificar que scrot esté instalado
if ! command -v scrot &>/dev/null; then
    echo "❌ Necesitas instalar 'scrot' para usar este script."
    exit 1
fi

# Modo de captura (área seleccionada o pantalla completa)
case "$1" in
    area)
        scrot -s "$filename"
        ;;
    full)
        scrot "$filename"
        ;;
    *)
        echo "Uso: $0 {area|full}"
        exit 1
        ;;
esac

# Copiar al portapapeles (si xclip está disponible)
if command -v xclip &>/dev/null; then
    xclip -selection clipboard -t image/png -i "$filename"
fi

# Notificación
notify-send "📸 Captura guardada y copiada al portapapeles" "$filename"
