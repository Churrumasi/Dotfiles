#!/bin/bash

# Pedir nombre del tema gráficamente (kdialog)
tema_nombre=$(kdialog --inputbox "Introduce el nombre del tema:" "" --title "Nuevo tema")
if [[ $? -ne 0 || -z "$tema_nombre" ]]; then
    kdialog --error "❌ Nombre del tema no puede estar vacío. Cancelando..."
    exit 1
fi

DEST_DIR="$HOME/.config/temas/$tema_nombre"
mkdir -p "$DEST_DIR" || {
    kdialog --error "❌ No se pudo crear el directorio: $DEST_DIR"
    exit 1
}

# Seleccionar imagen para el fondo (kdialog)
fondo_origen=$(kdialog --getopenfilename "$HOME" --title "Selecciona el fondo de pantalla")
if [[ $? -ne 0 || -z "$fondo_origen" ]]; then
    kdialog --error "⚠️ No se seleccionó ninguna imagen. Cancelando..."
    exit 1
fi

# Validar que el archivo sea imagen
if ! file "$fondo_origen" | grep -qE 'image|bitmap'; then
    kdialog --error "⚠️ El archivo seleccionado no es una imagen válida. Cancelando..."
    exit 1
fi

# Copiar y renombrar como fondo.png
cp "$fondo_origen" "$DEST_DIR/fondo.png" || {
    kdialog --error "❌ No se pudo copiar la imagen a $DEST_DIR"
    exit 1
}

# ────────────────────────────────────────────────
# Fondo animado opcional
# ────────────────────────────────────────────────
if kdialog --yesno "¿Quieres agregar un fondo animado (video .mp4) para este tema?" --title "Fondo animado"; then
    video_origen=$(kdialog --getopenfilename "$HOME" "*.mp4" --title "Selecciona el video de fondo animado (.mp4)")
    if [[ $? -eq 0 && -n "$video_origen" && -f "$video_origen" ]]; then
        cp "$video_origen" "$DEST_DIR/fondo.mp4" || {
            kdialog --error "⚠️ No se pudo copiar el video al tema."
        }
    else
        kdialog --msgbox "⏭️ No se seleccionó ningún video. Se usará fondo estático."
    fi
fi


FONDO="$DEST_DIR/fondo.png"
wal -i "$FONDO"

# Nombre del tema en minúsculas
THEME_NAME="my-wal-theme-${tema_nombre,,}"

# Definir carpeta fija para el repositorio
OOMOX_REPO="$HOME/.config/oomox-gtk-theme"

# Verificar si ya está clonado
if [[ -d "$OOMOX_REPO" ]]; then
    echo "✔️ Repositorio Oomox ya clonado, omitiendo clonación."
else
    kdialog --msgbox "🎨 Clonando repositorio Oomox por primera vez..."
    git clone https://github.com/themix-project/oomox-gtk-theme.git "$OOMOX_REPO" || {
        kdialog --error "❌ Error al clonar oomox-gtk-theme"
        exit 1
    }
fi

# Generar el tema desde el repositorio clonado
cd "$OOMOX_REPO" || {
    kdialog --error "❌ No se pudo acceder al directorio del repositorio clonado."
    exit 1
}
./change_color.sh -o "$THEME_NAME" <(cat ~/.cache/wal/colors-oomox) || {
    kdialog --error "❌ Error al generar el tema GTK con Oomox"
    exit 1
}
echo "$THEME_NAME" > "$DEST_DIR/gtk.txt"


# Buscar temas de iconos
icon_dirs=(/usr/share/icons ~/.icons)
icon_themes=()

for dir in "${icon_dirs[@]}"; do
    [[ -d "$dir" ]] || continue
    while IFS= read -r -d $'\0' theme; do
        icon_themes+=("$(basename "$theme")")
    done < <(find "$dir" -mindepth 1 -maxdepth 1 -type d -print0)
done

# Eliminar duplicados y ordenar
unique_themes=($(printf "%s\n" "${icon_themes[@]}" | sort -u))

# Mostrar lista al usuario con kdialog (combobox). Si la lista está vacía, se omite.
selected_icon=""
if [[ ${#unique_themes[@]} -gt 0 ]]; then
    # kdialog --combobox devuelve la selección por stdout; si el usuario cancela, el exit code != 0
    selected_icon=$(kdialog --combobox "Elige un tema de iconos para este tema visual:" "${unique_themes[@]}" --title "Seleccionar tema de iconos")
    if [[ $? -eq 0 && -n "$selected_icon" ]]; then
        echo "$selected_icon" > "$DEST_DIR/icon.txt"
    else
        kdialog --msgbox "⏭️ No se seleccionó tema de iconos. Se omitirá."
    fi
else
    kdialog --msgbox "⚠️ No se encontraron temas de iconos en los directorios habituales. Se omitirá."
fi

# Leer colores
WAL_COLORS="$HOME/.cache/wal/colors"
if [[ ! -f "$WAL_COLORS" ]]; then
    kdialog --error "❌ No se encontró el archivo de colores: $WAL_COLORS"
    exit 1
fi

mapfile -t colors < "$WAL_COLORS"
[[ "${#colors[@]}" -lt 16 ]] && {
    kdialog --error "❌ No se pudieron leer 16 colores de $WAL_COLORS"
    exit 1
}

# HEX -> RGB
hex_to_rgb() {
    local hex="${1#\#}"
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    echo "$r, $g, $b"
}
rgba_value=$(hex_to_rgb "${colors[3]}")

# Crear archivos
cat > "$DEST_DIR/dunstrc" <<EOF
[global]
    monitor = 0
    follow = mouse
    width = 300
    height = (0, 300)
    origin = bottom-right
    offset = (10, 40)
    scale = 0
    notification_limit = 5
    transparency = 0
    frame_color = "${colors[1]}"
    separator_color = "${colors[2]}"
    padding = 10
    horizontal_padding = 10
    text_icon_padding = 8
    icon_position = left
    max_icon_size = 64
    font = Monospace 10
    line_height = 0

[urgency_low]
    background = "${colors[0]}"
    foreground = "${colors[15]}"
    frame_color = "${colors[6]}"
    timeout = 4

[urgency_normal]
    background = "${colors[1]}"
    foreground = "${colors[15]}"
    frame_color = "${colors[4]}"
    timeout = 8

[urgency_critical]
    background = "${colors[2]}"
    foreground = "${colors[0]}"
    frame_color = "#FF0000"
    timeout = 0
EOF

cat > "$DEST_DIR/mitema.rasi" <<EOF
* {
    background:     ${colors[0]}FF;
    background-alt: ${colors[1]}FF;
    foreground:     ${colors[15]}FF;
    selected:       ${colors[4]}FF;
    active:         ${colors[3]}FF;
    urgent:         ${colors[8]}FF;
}
EOF

# Registrar tema
mkdir -p "$HOME/.config/scripts"
echo "$tema_nombre" > "$HOME/.config/scripts/tema-actual.txt"

# Confirmación para aplicar el tema (kdialog yesno)
kdialog --yesno "¿Quieres aplicar el tema ahora?" --title "Aplicar tema"
if [[ $? -eq 0 ]]; then
    if [[ -x "$HOME/.config/scripts/aplicar_tema.sh" ]]; then
        "$HOME/.config/scripts/aplicar_tema.sh"
    else
        kdialog --error "⚠️ El script aplicar_tema.sh no existe o no es ejecutable."
    fi
else
    kdialog --msgbox "⏭️ Aplicación del tema omitida."
fi
