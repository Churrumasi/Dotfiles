#!/bin/bash
#
# Script para generar un tema visual basado en Pywal, incluyendo:
# - Fondo estático y opcionalmente animado
# - Tema GTK generado con Oomox
# - Selección de tema de iconos
# - Generación de archivos de configuración (rofi, dunst)
#
# AGREGADO:
# Antes de elegir iconos, se muestra una vista previa tipo fastfetch
# con los 16 colores de Pywal generados.
#

#############################################
# 1. Pedir nombre del tema
#############################################
tema_nombre=$(kdialog --inputbox "Introduce el nombre del tema:" "" --title "Nuevo tema")

if [[ $? -ne 0 || -z "$tema_nombre" ]]; then
    kdialog --error "El nombre del tema no puede estar vacío. Cancelando..."
    exit 1
fi

DEST_DIR="$HOME/.config/temas/$tema_nombre"
mkdir -p "$DEST_DIR" || {
    kdialog --error "No se pudo crear el directorio: $DEST_DIR"
    exit 1
}


#############################################
# 2. Selección y validación del fondo
#############################################
fondo_origen=$(kdialog --getopenfilename "$HOME" --title "Selecciona el fondo de pantalla")
if [[ $? -ne 0 || -z "$fondo_origen" ]]; then
    kdialog --error "No se seleccionó ninguna imagen. Cancelando..."
    exit 1
fi

# Validar archivo como imagen
if ! file "$fondo_origen" | grep -qiE 'image|bitmap'; then
    kdialog --error "El archivo seleccionado no es una imagen válida."
    exit 1
fi

cp "$fondo_origen" "$DEST_DIR/fondo.png" || {
    kdialog --error "No se pudo copiar la imagen al tema."
    exit 1
}


#############################################
# 3. Fondo animado opcional (.mp4)
#############################################
if kdialog --yesno "¿Quieres agregar un fondo animado (video .mp4)?" --title "Fondo animado"; then
    video_origen=$(kdialog --getopenfilename "$HOME" "*.mp4" --title "Selecciona el video de fondo")
    if [[ $? -eq 0 && -n "$video_origen" ]]; then
        cp "$video_origen" "$DEST_DIR/fondo.mp4"
    fi
fi


#############################################
# 4. Ejecutar wal para generar la paleta
#############################################
wal -i "$DEST_DIR/fondo.png" -n

#############################################
# 4.5 Guardar config de Kitty generada por wal
#############################################

KITTY_COLORS="$HOME/.cache/wal/colors-kitty.conf"

if [[ -f "$KITTY_COLORS" ]]; then
    cp "$KITTY_COLORS" "$DEST_DIR/colors-kitty.conf"
fi


#############################################
# 5. Vista previa en 2 filas de 8 colores
#############################################
WAL_COLORS="$HOME/.cache/wal/colors"

if [[ ! -f "$WAL_COLORS" ]]; then
    kdialog --error "No se encontró el archivo de colores de Pywal."
    exit 1
fi

mapfile -t colors < "$WAL_COLORS"
if [[ ${#colors[@]} -lt 16 ]]; then
    kdialog --error "No se encontraron al menos 16 colores en $WAL_COLORS."
    exit 1
fi

preview="$DEST_DIR/preview.png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Tamaño total
total_w=400
total_h=80

# Medidas de cada cuadro
cols=8
rows=2
box_w=$((total_w / cols))
box_h=$((total_h / rows))

# Crear imágenes individuales
for i in $(seq 0 15); do
    color="${colors[$i]}"
    [[ $color == \#* ]] || color="#$color"
    convert -size "${box_w}x${box_h}" "xc:${color}" "$tmpdir/c${i}.png"
done

# Primera fila (colores 0–7)
convert +append "$tmpdir"/c{0..7}.png "$tmpdir/row1.png"

# Segunda fila (colores 8–15)
convert +append "$tmpdir"/c{8..15}.png "$tmpdir/row2.png"

# Unir filas sin espacios
convert -append "$tmpdir/row1.png" "$tmpdir/row2.png" "$preview"

# Mostrar en ventana pequeña
kdialog --imgbox "$preview" "$total_w" "$total_h" --title "Vista previa de colores"

#############################################
# 6. Tema GTK (Oomox)
#############################################
THEME_NAME="my-wal-theme-${tema_nombre,,}"
OOMOX_REPO="$HOME/.config/oomox-gtk-theme"

if [[ ! -d "$OOMOX_REPO" ]]; then
    kdialog --msgbox "Clonando repositorio de Oomox por primera vez."
    git clone https://github.com/themix-project/oomox-gtk-theme.git "$OOMOX_REPO" || {
        kdialog --error "Error al clonar Oomox."
        exit 1
    }
fi

cd "$OOMOX_REPO" || exit 1

./change_color.sh -o "$THEME_NAME" <(cat ~/.cache/wal/colors-oomox) || {
    kdialog --error "Error al generar el tema GTK."
    exit 1
}

echo "$THEME_NAME" > "$DEST_DIR/gtk.txt"


#############################################
# 7. Selección de tema de iconos
#############################################
icon_dirs=(/usr/share/icons ~/.icons)
icon_themes=()

for dir in "${icon_dirs[@]}"; do
    [[ -d "$dir" ]] || continue
    while IFS= read -r -d $'\0' theme; do
        icon_themes+=("$(basename "$theme")")
    done < <(find "$dir" -mindepth 1 -maxdepth 1 -type d -print0)
done

unique_themes=($(printf "%s\n" "${icon_themes[@]}" | sort -u))

if [[ ${#unique_themes[@]} -gt 0 ]]; then
    selected_icon=$(kdialog --combobox "Elige un tema de iconos:" "${unique_themes[@]}" --title "Iconos")
    if [[ $? -eq 0 && -n "$selected_icon" ]]; then
        echo "$selected_icon" > "$DEST_DIR/icon.txt"
    fi
fi


#############################################
# 8. Generar dunstrc
#############################################
hex_to_rgb() {
    local hex="${1#\#}"
    echo "$((16#${hex:0:2})), $((16#${hex:2:2})), $((16#${hex:4:2}))"
}

rgba_value=$(hex_to_rgb "${colors[3]}")

cat > "$DEST_DIR/dunstrc" <<EOF
[global]
    monitor = 0
    follow = mouse
    width = 300
    height = (0, 300)
    origin = bottom-right
    offset = (10, 40)
    frame_color = "${colors[1]}"
    separator_color = "${colors[2]}"
    padding = 10
    text_icon_padding = 8
    max_icon_size = 64
    font = Monospace 10

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


#############################################
# 9. Generar estilo básico para rofi
#############################################
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

#############################################
# 10. Generar configuración de Polybar
#############################################

BATTERY=$(ls /sys/class/power_supply | grep BAT | head -n1)
ADAPTER=$(ls /sys/class/power_supply | grep ADP | head -n1)

cat > "$DEST_DIR/polybar.ini" <<EOF

[colors]
background = ${colors[0]}
background-alt = ${colors[1]}
foreground = ${colors[15]}
foreground-alt = ${colors[7]}

blue = ${colors[4]}
cyan = ${colors[6]}
green = ${colors[2]}
yellow = ${colors[3]}
red = ${colors[1]}
purple = ${colors[5]}
orange = ${colors[9]}

[bar/main]
width = 100%
height = 28
radius = 0
bottom = true

background = \${colors.background}
foreground = \${colors.foreground}

line-size = 2
line-color = \${colors.blue}

padding-left = 1
padding-right = 1
module-margin = 1

font-0 = "JetBrainsMono Nerd Font:size=10;2"
font-1 = "JetBrainsMono Nerd Font:size=12;3"

tray-position = none
wm-restack = i3
enable-ipc = true

modules-left = arch i3
modules-center = window
modules-right = tray audio battery clock

[module/arch]
type = custom/text
content = 
content-foreground = \${colors.blue}
content-padding = 1
click-left = ~/.config/scripts/rofi.sh
click-middle = ~/.config/scripts/rofi.sh
click-right = ~/.config/scripts/rofi.sh

[module/i3]
type = internal/i3
pin-workspaces = true
show-urgent = true
strip-wsnumbers = true

ws-icon-default = 

label-focused = %name%
label-focused-foreground = \${colors.background}
label-focused-background = \${colors.blue}
label-focused-padding = 1

label-unfocused = %name%
label-unfocused-foreground = \${colors.foreground-alt}
label-unfocused-padding = 1

label-urgent = %name%
label-urgent-background = \${colors.red}
label-urgent-padding = 1

[module/window]
type = internal/xwindow
label = %title%
label-maxlen = 35
label-ellipsis = true
label-padding = 1
label-foreground = \${colors.cyan}

[module/audio]
type = internal/pulseaudio
interval = 5
format-volume =   <label-volume>
label-volume = %percentage%%

format-muted =  muted

; -------- Clock --------
[module/clock]
type = internal/date
interval = 1

date = %H:%M
date-alt = %Y-%m-%d %H:%M

label =  %date%
label-foreground = ${colors[3]}

[module/battery]
type = internal/battery
battery = ${BATTERY}
adapter = ${ADAPTER}
poll-interval = 5
full-at = 98

format-charging =  <label-charging>
format-discharging = <ramp-capacity> <label-discharging>
format-full =  full

label-charging = %percentage%%
label-discharging = %percentage%%
label-full = 100%

ramp-capacity-0 = 
ramp-capacity-1 = 
ramp-capacity-2 = 
ramp-capacity-3 = 
ramp-capacity-4 = 

[module/tray]
type = internal/tray
tray-size = 18
tray-spacing = 6
tray-padding = 2
tray-background = \${colors.background}

[settings]
screenchange-reload = true
pseudo-transparency = false
EOF

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

[font]
size = 7.5

[font.normal]
family = "MesloLGS NF"
EOF

#############################################
# 11. Mensaje final
#############################################
kdialog --msgbox "Tema creado correctamente."
