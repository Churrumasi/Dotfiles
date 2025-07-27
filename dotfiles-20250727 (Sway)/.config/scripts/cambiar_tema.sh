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

TEMA_PATH="$TEMAS_DIR/$TEMA"
FONDO="$TEMA_PATH/fondo.png"
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

# Cambiar fondo
pkill swaybg
swaybg -i "$FONDO" --mode fill &

# Cambiar tema GTK
gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME"

# Cambiar tema de iconos
gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME"

# Reemplazar el style.css de waybar
cp "$STYLE" ~/.config/waybar/style.css
pkill waybar && waybar &

# Reemplazar configuración de Alacritty
cp "$ALACRITTY" ~/.config/alacritty/alacritty.toml

# Reemplazar el tema de rofi
mkdir -p ~/.config/rofi/colors
cp "$ROFI_THEME_FILE" ~/.config/rofi/colors/mitema.rasi

# Aplicar colores wal
wal -i "$FONDO"
# Copiar colores de wal a greetd para tuigreet
#if [ -f "$HOME/.cache/wal/colors" ]; then
#    sudo cp "$HOME/.cache/wal/colors" /etc/greetd/colors
#    sudo chown greeter:greeter /etc/greetd/colors
#fi

# Notificar y guardar tema actual
notify-send "Tema cambiado" "Tema activo: $TEMA"
echo "$TEMA" > "$SCRIPTS_DIR/tema-actual.txt"
