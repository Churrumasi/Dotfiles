#!/bin/bash

# Elegir archivo
archivo=$(zenity --file-selection --title="Selecciona un archivo MP4 o JPG/JPEG")
[ $? -ne 0 ] && exit 0  # Si cancela

# Detectar extensión
extension="${archivo##*.}"
extension=$(echo "$extension" | tr '[:upper:]' '[:lower:]')

# Ruta sugerida
nombre_base=$(basename "$archivo" ."$extension")
directorio_base=$(dirname "$archivo")

# Función para mostrar notificaciones
notificar() {
  zenity --notification --text="$1"
}

# Conversión según tipo
case "$extension" in
  mp4)
    sugerido="$directorio_base/$nombre_base.webp"
    salida=$(zenity --file-selection --save --confirm-overwrite --title="Guardar como .webp" --filename="$sugerido")
    [ $? -ne 0 ] && exit 0

    fps=$(ffprobe -v 0 -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 "$archivo" | bc)

    ffmpeg -i "$archivo" -vf "fps=$fps,scale=iw:ih:flags=lanczos" \
      -lossless 1 -loop 0 -preset default -an "$salida" && \
      notificar "Conversión MP4 → WEBP completada: $(basename "$salida")" || \
      zenity --error --text="Error al convertir MP4 a WEBP"
    ;;
    
  jpg|jpeg)
    sugerido="$directorio_base/$nombre_base.png"
    salida=$(zenity --file-selection --save --confirm-overwrite --title="Guardar como .png" --filename="$sugerido")
    [ $? -ne 0 ] && exit 0

    convert "$archivo" "$salida" && \
      notificar "Conversión JPG/JPEG → PNG completada: $(basename "$salida")" || \
      zenity --error --text="Error al convertir JPG/JPEG a PNG"
    ;;
    
  *)
    zenity --error --text="Formato no compatible: .$extension"
    ;;
esac
