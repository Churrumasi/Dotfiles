#!/usr/bin/env bash

set -euo pipefail

# ============================================
# Conversor moderno de imágenes/animaciones
# ============================================

# Dependencias:
# ffmpeg
# ffprobe
# zenity
# imagemagick

# ============================================
# Funciones
# ============================================

error() {
    zenity --error --width=320 --text="$1"
}

notify() {
    zenity --notification --text="$1"
}

need() {
    command -v "$1" >/dev/null 2>&1 || {
        error "Falta instalar: $1"
        exit 1
    }
}

# ============================================
# Dependencias
# ============================================

need ffmpeg
need ffprobe
need zenity
need magick

# ============================================
# Seleccionar archivo
# ============================================

archivo=$(zenity --file-selection \
    --title="Selecciona archivo")

[ $? -ne 0 ] && exit 0

extension="${archivo##*.}"
extension=$(echo "$extension" | tr '[:upper:]' '[:lower:]')

nombre="$(basename "$archivo" ."$extension")"
directorio="$(dirname "$archivo")"

# ============================================
# VIDEO → ANIMACIÓN
# ============================================

if [[ "$extension" =~ ^(mp4|mkv|webm|mov)$ ]]; then

    formato=$(zenity --list \
        --title="Formato de salida" \
        --column="Formato" \
        "WEBP Lossless" \
        "AVIF" \
        "GIF HQ" \
        --height=260 \
        --width=320)

    [ $? -ne 0 ] && exit 0

    fps_raw=$(ffprobe -v 0 \
        -select_streams v:0 \
        -show_entries stream=r_frame_rate \
        -of default=noprint_wrappers=1:nokey=1 \
        "$archivo")

    fps=$(awk "BEGIN{
        split(\"$fps_raw\",a,\"/\");
        if(a[2]==0) print 30;
        else print a[1]/a[2]
    }")

    case "$formato" in

    # ========================================
    # WEBP LOSSLESS
    # ========================================

    "WEBP Lossless")

        salida=$(zenity --file-selection \
            --save \
            --confirm-overwrite \
            --filename="$directorio/$nombre.webp")

        [ $? -ne 0 ] && exit 0

        ffmpeg -y -i "$archivo" \
            -vf "fps=$fps" \
            -c:v libwebp_anim \
            -lossless 1 \
            -quality 100 \
            -compression_level 6 \
            -loop 0 \
            -an \
            "$salida"

        notify "WEBP lossless creado"
        ;;

    # ========================================
    # AVIF
    # ========================================

    "AVIF")

        salida=$(zenity --file-selection \
            --save \
            --confirm-overwrite \
            --filename="$directorio/$nombre.avif")

        [ $? -ne 0 ] && exit 0

        ffmpeg -y -i "$archivo" \
            -vf "fps=$fps" \
            -c:v libaom-av1 \
            -crf 0 \
            -still-picture 0 \
            -cpu-used 0 \
            -row-mt 1 \
            "$salida"

        notify "AVIF creado"
        ;;

    # ========================================
    # GIF HQ
    # ========================================

    "GIF HQ")

        salida=$(zenity --file-selection \
            --save \
            --confirm-overwrite \
            --filename="$directorio/$nombre.gif")

        [ $? -ne 0 ] && exit 0

        palette="/tmp/${nombre}_palette.png"

        ffmpeg -y -i "$archivo" \
            -vf "fps=$fps,palettegen=stats_mode=full" \
            "$palette"

        ffmpeg -y -i "$archivo" -i "$palette" \
            -lavfi "fps=$fps[x];[x][1:v]paletteuse=dither=sierra2_4a" \
            "$salida"

        rm -f "$palette"

        notify "GIF HQ creado"
        ;;

    esac

# ============================================
# IMAGEN → IMAGEN
# ============================================

elif [[ "$extension" =~ ^(jpg|jpeg|png|bmp|tga|tiff|webp)$ ]]; then

    formato=$(zenity --list \
        --title="Convertir imagen" \
        --column="Formato" \
        "PNG" \
        "WEBP Lossless" \
        "AVIF" \
        "BMP" \
        "TGA" \
        "TIFF" \
        "farbfeld" \
        --height=320 \
        --width=320)

    [ $? -ne 0 ] && exit 0

    case "$formato" in

    "PNG")
        ext="png"
        ;;

    "WEBP Lossless")
        ext="webp"
        ;;

    "AVIF")
        ext="avif"
        ;;

    "BMP")
        ext="bmp"
        ;;

    "TGA")
        ext="tga"
        ;;

    "TIFF")
        ext="tiff"
        ;;

    "farbfeld")
        ext="ff"
        ;;

    esac

    salida=$(zenity --file-selection \
        --save \
        --confirm-overwrite \
        --filename="$directorio/$nombre.$ext")

    [ $? -ne 0 ] && exit 0

    case "$ext" in

    png)
        magick "$archivo" PNG24:"$salida"
        ;;

    webp)
        magick "$archivo" -define webp:lossless=true "$salida"
        ;;

    avif)
        magick "$archivo" "$salida"
        ;;

    bmp|tga|tiff)
        magick "$archivo" "$salida"
        ;;

    ff)
        ffmpeg -y -i "$archivo" "$salida"
        ;;

    esac

    notify "Conversión completada"

else

    error "Formato no compatible"

fi
```
