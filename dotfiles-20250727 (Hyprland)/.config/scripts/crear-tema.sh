#!/bin/bash

# Pedir nombre del tema gráficamente
tema_nombre=$(zenity --entry --title="Nuevo tema" --text="Introduce el nombre del tema:")
if [[ -z "$tema_nombre" ]]; then
    zenity --error --text="❌ Nombre del tema no puede estar vacío. Cancelando..."
    exit 1
fi

DEST_DIR="$HOME/.config/temas/$tema_nombre"
mkdir -p "$DEST_DIR" || {
    zenity --error --text="❌ No se pudo crear el directorio: $DEST_DIR"
    exit 1
}

# Seleccionar imagen para el fondo
fondo_origen=$(zenity --file-selection --title="Selecciona el fondo de pantalla")
if [[ -z "$fondo_origen" ]]; then
    zenity --error --text="⚠️ No se seleccionó ninguna imagen. Cancelando..."
    exit 1
fi

# Validar que el archivo sea imagen
if ! file "$fondo_origen" | grep -qE 'image|bitmap'; then
    zenity --error --text="⚠️ El archivo seleccionado no es una imagen válida. Cancelando..."
    exit 1
fi

# Copiar y renombrar como fondo.png
cp "$fondo_origen" "$DEST_DIR/fondo.png" || {
    zenity --error --text="❌ No se pudo copiar la imagen a $DEST_DIR"
    exit 1
}

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
    zenity --info --text="🎨 Clonando repositorio Oomox por primera vez..."
    git clone https://github.com/themix-project/oomox-gtk-theme.git "$OOMOX_REPO" || {
        zenity --error --text="❌ Error al clonar oomox-gtk-theme"
        exit 1
    }
fi

# Generar el tema desde el repositorio clonado
cd "$OOMOX_REPO" || {
    zenity --error --text="❌ No se pudo acceder al directorio del repositorio clonado."
    exit 1
}
./change_color.sh -o "$THEME_NAME" <(cat ~/.cache/wal/colors-oomox) || {
    zenity --error --text="❌ Error al generar el tema GTK con Oomox"
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

# Mostrar lista al usuario con Zenity
selected_icon=$(zenity --list --title="Seleccionar tema de iconos" \
    --text="Elige un tema de iconos para este tema visual:" \
    --column="Temas disponibles" "${unique_themes[@]}")

if [[ -n "$selected_icon" ]]; then
    echo "$selected_icon" > "$DEST_DIR/icon.txt"
else
    zenity --info --text="⏭️ No se seleccionó tema de iconos. Se omitirá."
fi

# Leer colores
WAL_COLORS="$HOME/.cache/wal/colors"
mapfile -t colors < "$WAL_COLORS"
[[ "${#colors[@]}" -lt 16 ]] && {
    zenity --error --text="❌ No se pudieron leer 16 colores de $WAL_COLORS"
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
cat > "$DEST_DIR/alacritty.toml" <<EOF
[colors.primary]
background = "${colors[0]}"
foreground = "${colors[15]}"

[colors.cursor]
text = "${colors[0]}"
cursor = "${colors[15]}"

[colors.normal]
black   = "${colors[0]}"
red     = "${colors[1]}"
green   = "${colors[2]}"
yellow  = "${colors[3]}"
blue    = "${colors[4]}"
magenta = "${colors[5]}"
cyan    = "${colors[6]}"
white   = "${colors[7]}"

[colors.bright]
black   = "${colors[8]}"
red     = "${colors[9]}"
green   = "${colors[10]}"
yellow  = "${colors[11]}"
blue    = "${colors[12]}"
magenta = "${colors[13]}"
cyan    = "${colors[14]}"
white   = "${colors[15]}"

[font.normal]
family = "MesloLGS NF"
EOF

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

cat > "$DEST_DIR/style.css" <<EOF
* {
  font-family: "JetBrainsMono Nerd Font", "Font Awesome 6 Free", sans-serif;
  font-size: 12px;
  min-height: 0;
  color: ${colors[15]};
}

window#waybar {
  background-color: ${colors[0]};
  border-top: 2px solid ${colors[4]};
  box-shadow: inset 0 1px 0 ${colors[6]};
  padding: 0 8px;
}

#workspaces {
  margin: 0 4px;
}
#workspaces button {
  padding: 2px 8px;
  margin: 2px 2px;
  background-color: transparent;
  border: none;
  color: ${colors[5]};
  transition: background 0.3s, color 0.3s;
}
#workspaces button.active {
  background-color: ${colors[1]};
  color: #ffffff;
  border-radius: 4px;
}
#workspaces button.urgent {
  color: #ff5555;
}

#clock,
#tray,
#custom-arch,
#custom-power,
#window,
#custom-cliphist,
#pulseaudio,
#battery,
#custom-notifications,
#custom-nm,
#custom-bluetooth,
#custom-screenshot {
  padding: 2px 10px;
  background-color: rgba($rgba_value, 0.1);
  border-radius: 6px;
  margin: 2px 4px;
}

#clock:hover {
  background-color: ${colors[5]};
  color: ${colors[0]};
}
#custom-arch {
  color: ${colors[6]};
}
#custom-arch:hover {
  background-color: ${colors[1]};
  color: #ffffff;
}
#custom-power {
  color: #ff5555;
}
#custom-power:hover {
  background-color: ${colors[5]};
  color: ${colors[0]};
}
#window {
  color: ${colors[8]};
}

#custom-cliphist:hover,
#pulseaudio:hover,
#battery:hover,
#custom-notifications:hover {
  background-color: ${colors[5]};
  color: ${colors[0]};
}

#custom-nm {
  color: ${colors[4]};
}
#custom-nm:hover {
  background-color: ${colors[6]};
  color: ${colors[0]};
}

#custom-bluetooth,
#custom-screenshot {
  color: ${colors[3]};
}
#custom-bluetooth:hover,
#custom-screenshot:hover {
  background-color: ${colors[6]};
  color: ${colors[0]};
}
EOF


# Registrar tema
echo "$tema_nombre" > "$HOME/.config/scripts/tema-actual.txt"

# Confirmación para aplicar el tema
zenity --question --text="¿Quieres aplicar el tema ahora?" --title="Aplicar tema"
if [[ $? -eq 0 ]]; then
    if [[ -x "$HOME/.config/scripts/aplicar_tema.sh" ]]; then
        "$HOME/.config/scripts/aplicar_tema.sh"
    else
        zenity --error --text="⚠️ El script aplicar_tema.sh no existe o no es ejecutable."
    fi
else
    zenity --info --text="⏭️ Aplicación del tema omitida."
fi
