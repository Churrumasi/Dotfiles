#!/bin/bash
set -e

#############################################
# 1. Nombre del tema
#############################################
tema_nombre=$(kdialog --inputbox "Introduce el nombre del tema:" "" --title "Nuevo tema")
[[ -z "$tema_nombre" ]] && {
    kdialog --error "El nombre del tema no puede estar vacío."
    exit 1
}

DEST_DIR="$HOME/.config/temas/$tema_nombre"
mkdir -p "$DEST_DIR"

#############################################
# 2. Seleccionar fondo
#############################################
fondo_origen=$(kdialog --getopenfilename "$HOME" --title "Selecciona el fondo de pantalla")
[[ -z "$fondo_origen" ]] && exit 1

file "$fondo_origen" | grep -qi image || {
    kdialog --error "El archivo no es una imagen válida."
    exit 1
}

cp "$fondo_origen" "$DEST_DIR/fondo.png"



#############################################
# 3. Ejecutar Pywal
#############################################
wal -i "$DEST_DIR/fondo.png" -n

#############################################
# 4. Vista previa de colores
#############################################
WAL_COLORS="$HOME/.cache/wal/colors"
mapfile -t colors < "$WAL_COLORS"

tmpdir=$(mktemp -d)
preview="$DEST_DIR/preview.png"

for i in {0..15}; do
    convert -size 50x40 "xc:${colors[$i]}" "$tmpdir/c$i.png"
done

convert +append "$tmpdir"/c{0..7}.png "$tmpdir/row1.png"
convert +append "$tmpdir"/c{8..15}.png "$tmpdir/row2.png"
convert -append "$tmpdir/row1.png" "$tmpdir/row2.png" "$preview"

kdialog --imgbox "$preview" 400 80 --title "Colores Pywal"

rm -rf "$tmpdir"

#############################################
# 5. Tema GTK (Oomox)
#############################################
THEME_NAME="my-wal-theme-${tema_nombre,,}"
OOMOX_REPO="$HOME/.config/oomox-gtk-theme"

if [[ ! -d "$OOMOX_REPO" ]]; then
    kdialog --msgbox "Clonando Oomox por primera vez..."
    git clone https://github.com/themix-project/oomox-gtk-theme.git "$OOMOX_REPO"
fi

cd "$OOMOX_REPO"
./change_color.sh -o "$THEME_NAME" <(cat ~/.cache/wal/colors-oomox)

echo "$THEME_NAME" > "$DEST_DIR/gtk.txt"

#############################################
# 6. Tema de iconos
#############################################
icon_dirs=(/usr/share/icons ~/.icons)
themes=()

for d in "${icon_dirs[@]}"; do
    [[ -d "$d" ]] || continue
    for t in "$d"/*; do
        [[ -d "$t" ]] && themes+=("$(basename "$t")")
    done
done

mapfile -t themes < <(printf "%s\n" "${themes[@]}" | sort -u)

selected_icon=$(kdialog --combobox "Selecciona un tema de iconos:" "${themes[@]}" --title "Iconos")
[[ -n "$selected_icon" ]] && echo "$selected_icon" > "$DEST_DIR/icon.txt"

#############################################
# 7. Utilidades de color
#############################################
hex_to_rgb() {
    h="${1#\#}"
    echo "$((16#${h:0:2})), $((16#${h:2:2})), $((16#${h:4:2}))"
}

rgba_value=$(hex_to_rgb "${colors[3]}")

#############################################
# 9. Alacritty
#############################################
cat > "$DEST_DIR/alacritty.toml" <<EOF
[colors.primary]
background = "${colors[0]}"
foreground = "${colors[15]}"

[colors.normal]
black = "${colors[0]}"
red = "${colors[1]}"
green = "${colors[2]}"
yellow = "${colors[3]}"
blue = "${colors[4]}"
magenta = "${colors[5]}"
cyan = "${colors[6]}"
white = "${colors[7]}"

[colors.bright]
black = "${colors[8]}"
red = "${colors[9]}"
green = "${colors[10]}"
yellow = "${colors[11]}"
blue = "${colors[12]}"
magenta = "${colors[13]}"
cyan = "${colors[14]}"
white = "${colors[15]}"

[font.normal]
family = "MesloLGS NF"
EOF

#############################################
# 10. Dunst
#############################################
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
# 11. Rofi
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
# 12. Waybar (style.css) — COMPLETO
#############################################

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

#############################################
# 12.5 Colores de bordes Hyprland (Waybar-based)
#############################################

# Fondo de Waybar → borde inactivo
inactive_hex="${colors[0]#\#}"

# Línea superior de Waybar → borde activo
active_hex="${colors[4]#\#}"

# Alpha (ajustables)
ACTIVE_ALPHA="FF"     # totalmente visible
INACTIVE_ALPHA="AA"   # semi-transparente

cat > "$DEST_DIR/colors.conf" <<EOF
# Bordes Hyprland - Tema: $tema_nombre
# Activo  -> color línea superior Waybar
# Inactivo-> fondo Waybar

general {
    col.active_border = rgba(${active_hex}${ACTIVE_ALPHA})
    col.inactive_border = rgba(${inactive_hex}${INACTIVE_ALPHA})
}
EOF
	

#############################################
# 13. Registrar tema
#############################################
mkdir -p "$HOME/.config/scripts"
echo "$tema_nombre" > "$HOME/.config/scripts/tema-actual.txt"

#############################################
# 14. Scripts opcionales
#############################################
kdialog --yesno "¿Ejecutar convertir.sh?" && "$HOME/.config/scripts/convertir.sh"
kdialog --yesno "¿Aplicar el tema ahora?" && "$HOME/.config/scripts/aplicar_tema.sh"

#############################################
# 15. Final
#############################################
kdialog --msgbox "Tema \"$tema_nombre\" creado correctamente 🎨"
