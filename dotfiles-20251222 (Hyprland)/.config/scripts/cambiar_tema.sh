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
# Aplicar colores con wal
wal -i "$FONDO1"

#############################################
# Kvantum (Qt) usando pywal
#############################################

KVANTUM_THEME="wal-$TEMA"
KVANTUM_DIR="$HOME/.config/Kvantum/$KVANTUM_THEME"

# Crear carpeta del tema Kvantum
mkdir -p "$KVANTUM_DIR"

# Copiar y renombrar archivos generados por wal
if [[ -f ~/.cache/wal/pywal.kvconfig && -f ~/.cache/wal/pywal.svg ]]; then
    cp ~/.cache/wal/pywal.kvconfig \
       "$KVANTUM_DIR/$KVANTUM_THEME.kvconfig"

    cp ~/.cache/wal/pywal.svg \
       "$KVANTUM_DIR/$KVANTUM_THEME.svg"

    # Aplicar tema Kvantum
    if command -v kvantummanager &>/dev/null; then
        kvantummanager --set "$KVANTUM_THEME"
    fi
else
    echo "Archivos pywal para Kvantum no encontrados"
fi


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
HYPR_COLORS_SRC="$TEMA_PATH/colors.conf"
HYPR_COLORS_DEST="$HOME/.config/hypr/colors.conf"

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
#############################################
# Forzar tema GTK3 y GTK4
#############################################

GTK_THEME_NAME="$GTK_THEME"

mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0

cat > ~/.config/gtk-3.0/settings.ini <<EOF
[Settings]
gtk-theme-name=$GTK_THEME_NAME
gtk-icon-theme-name=$ICON_THEME
gtk-font-name=Sans 10
gtk-application-prefer-light-theme=true
EOF

cat > ~/.config/gtk-4.0/settings.ini <<EOF
[Settings]
gtk-theme-name=$GTK_THEME_NAME
gtk-icon-theme-name=$ICON_THEME
gtk-font-name=Sans 10
gtk-application-prefer-light-theme=true
EOF

# Aplicar estilo a Waybar
cp "$STYLE" ~/.config/waybar/style.css
pkill waybar && waybar &

# Aplicar configuración a Alacritty
cp "$ALACRITTY" ~/.config/alacritty/alacritty.toml
if [[ -f "$HYPR_COLORS_SRC" ]]; then
    mkdir -p "$(dirname "$HYPR_COLORS_DEST")"
    cp "$HYPR_COLORS_SRC" "$HYPR_COLORS_DEST"

    # Recargar Hyprland para aplicar bordes
    if command -v hyprctl &>/dev/null; then
        hyprctl reload &>/dev/null
    fi
else
    echo "colors.conf no encontrado para el tema $TEMA"
fi
# Aplicar tema a Rofi
mkdir -p ~/.config/rofi/colors
cp "$ROFI_THEME_FILE" ~/.config/rofi/colors/mitema.rasi


hyprctl reload

export GTK_THEME="$GTK_THEME"
# Notificar y guardar tema actual
notify-send "Tema cambiado" "Tema activo: $TEMA"
echo "$TEMA" > "$SCRIPTS_DIR/tema-actual.txt"
