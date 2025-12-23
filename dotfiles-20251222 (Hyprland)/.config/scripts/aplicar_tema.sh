#!/bin/bash

TEMAS_DIR="$HOME/.config/temas"
SCRIPTS_DIR="$HOME/.config/scripts"

# Si no hay archivo tema-actual.txt, aplicar un tema por defecto
if [ ! -f "$SCRIPTS_DIR/tema-actual.txt" ]; then
    DEFAULT_TEMA="Lynette" # <-- cambia por el nombre de tu tema favorito
else
    DEFAULT_TEMA=$(cat "$SCRIPTS_DIR/tema-actual.txt")
fi

# Si el tema no existe, salir
[ ! -d "$TEMAS_DIR/$DEFAULT_TEMA" ] && exit 1

TEMA_PATH="$TEMAS_DIR/$DEFAULT_TEMA"

# Buscar fondo compatible (excluyendo fondo.png si hay otros disponibles)
FORMATOS_VALIDOS=("jpeg" "jpg" "gif" "pnm" "tga" "tiff" "tif" "webp" "bmp" "farbfeld")
FONDO1="$TEMA_PATH/fondo.png"
FONDO=""
for ext in "${FORMATOS_VALIDOS[@]}"; do
    archivo=$(find "$TEMA_PATH" -maxdepth 1 -iname "*.${ext}" ! -name "fondo.png" | head -n 1)
    if [[ -n "$archivo" ]]; then
        FONDO="$archivo"
        break
    fi
done
# Si no se encontró fondo alternativo, usar fondo.png
[ -z "$FONDO" ] && FONDO="$FONDO1"

STYLE="$TEMA_PATH/style.css"
ALACRITTY="$TEMA_PATH/alacritty.toml"
DUNST="$TEMA_PATH/dunstrc"
GTK_FILE="$TEMA_PATH/gtk.txt"
ICON_FILE="$TEMA_PATH/icon.txt"
ROFI_THEME_FILE="$TEMA_PATH/mitema.rasi"
wal -i "$FONDO1
# Leer tema GTK e íconos
GTK_THEME=$(cat "$GTK_FILE" 2>/dev/null || echo "my-wal-theme")
ICON_THEME=$(cat "$ICON_FILE" 2>/dev/null || echo "Tela-circle-blue")

# Cambiar fondo de pantalla con swww
if command -v swww &>/dev/null; then
    swww init &>/dev/null
    sleep 0.5
    swww img "$FONDO" --transition-type grow --transition-duration 1
else
    echo "⚠️ swww no está instalado. Saltando fondo de pantalla."
fi

# Cambiar tema GTK e iconos (si tienes gsettings y usas GNOME o similar)
if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME"
    gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME"
fi

# Aplicar estilo de Waybar
cp "$STYLE" ~/.config/waybar/style.css
pkill waybar && waybar &

# Aplicar tema de Rofi
mkdir -p ~/.config/rofi/colors
cp "$ROFI_THEME_FILE" ~/.config/rofi/colors/mitema.rasi

# Configurar Alacritty
cp "$ALACRITTY" ~/.config/alacritty/alacritty.toml


# Configurar Dunst
cp "$DUNST" ~/.config/dunst/dunstrc
pkill dunst && dunst &

# Guardar tema actual
echo "$DEFAULT_TEMA" > "$SCRIPTS_DIR/tema-actual.txt"

# Notificación de éxito
notify-send "🎨 Tema aplicado" "Tema activo: $DEFAULT_TEMA"
