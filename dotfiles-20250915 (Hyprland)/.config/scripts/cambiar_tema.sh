#!/bin/bash

TEMAS_DIR="$HOME/.config/temas"
SCRIPTS_DIR="$HOME/.config/scripts"

# Mostrar lista de temas disponibles con preview usando rofi
TEMA=$(ls "$TEMAS_DIR" | while read -r dir; do
    echo -en "$dir\x00icon\x1f$TEMAS_DIR/$dir/fondo.png\n"
done | rofi -dmenu \
    -theme ~/.config/rofi/launchers/type-2/style-2.rasi \
    -p "Temas")

# Si no selecciona nada, salir
[ -z "$TEMA" ] && exit
FORMATOS_VALIDOS=("jpeg" "jpg" "gif" "pnm" "tga" "tiff" "tif" "webp" "bmp" "farbfeld")
TEMA_PATH="$TEMAS_DIR/$TEMA"
FONDO1="$TEMA_PATH/fondo.png"
# Buscar una imagen compatible en el tema (excluyendo fondo.png)
FONDO=""
for ext in "${FORMATOS_VALIDOS[@]}"; do
    archivo=$(find "$TEMA_PATH" -maxdepth 1 -iname "*.${ext}" ! -name "fondo.png" | head -n 1)
    if [[ -n "$archivo" ]]; then
        FONDO="$archivo"
        break
    fi
done

# Si no se encontró ningún archivo compatible, usar fondo.png
if [[ -z "$FONDO" ]]; then
    FONDO="$TEMA_PATH/fondo.png"
fi

STYLE="$TEMA_PATH/style.css"
ALACRITTY="$TEMA_PATH/alacritty.toml"
DUNST="$TEMA_PATH/dunstrc"
GTK_FILE="$TEMA_PATH/gtk.txt"
ICON_FILE="$TEMA_PATH/icon.txt"
ROFI_THEME_FILE="$TEMA_PATH/mitema.rasi"

# Leer nombre de tema GTK e iconos
GTK_THEME=$(cat "$GTK_FILE" 2>/dev/null || echo "my-wal-theme")
ICON_THEME=$(cat "$ICON_FILE" 2>/dev/null || echo "Tela-circle-blue")

# Reemplazar configuración de dunst
cp "$DUNST" ~/.config/dunst/dunstrc
pkill dunst && dunst &

# Cambiar fondo con swww (reemplazo de swaybg en Hyprland)
if command -v swww &>/dev/null; then
    swww init &>/dev/null
    sleep 0.5
    swww img "$FONDO" --transition-type grow --transition-duration 1
else
    echo "swww no está instalado. Saltando fondo de pantalla."
fi

# Cambiar tema GTK e iconos (si tienes gsettings disponible)
if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME"
    gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME"
fi

# Aplicar estilo a Waybar
cp "$STYLE" ~/.config/waybar/style.css
pkill waybar && waybar &

# Aplicar configuración a Alacritty
cp "$ALACRITTY" ~/.config/alacritty/alacritty.toml

# Aplicar tema a Rofi
mkdir -p ~/.config/rofi/colors
cp "$ROFI_THEME_FILE" ~/.config/rofi/colors/mitema.rasi

# Aplicar colores con wal
wal -i "$FONDO1"

# Notificar y guardar tema actual
notify-send "Tema cambiado" "Tema activo: $TEMA"
echo "$TEMA" > "$SCRIPTS_DIR/tema-actual.txt"
