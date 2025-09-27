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
FONDO="$TEMA_PATH/fondo.png"
STYLE="$TEMA_PATH/style.css"
ALACRITTY="$TEMA_PATH/alacritty.toml"
DUNST="$TEMA_PATH/dunstrc"
GTK_FILE="$TEMA_PATH/gtk.txt"
ICON_FILE="$TEMA_PATH/icon.txt"
ROFI_THEME_FILE="$TEMA_PATH/mitema.rasi"

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
cp "$ROFI_THEME_FILE" ~/.config/rofi/colors/mitema.rasi

# Configurar Alacritty
cp "$ALACRITTY" ~/.config/alacritty/alacritty.toml

# Aplicar wal (por si quieres regenerar cache de colores)
wal -i "$FONDO"

# Configurar Dunst
cp "$DUNST" ~/.config/dunst/dunstrc
pkill dunst && dunst &
