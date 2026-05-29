#!/bin/bash

TEMAS_DIR="$HOME/.config/temas"
SCRIPTS_DIR="$HOME/.config/scripts"

# Si no hay archivo tema-actual.txt, aplicar un tema por defecto
if [ ! -f "$SCRIPTS_DIR/tema-actual.txt" ]; then
    DEFAULT_TEMA="Lynette" # <-- puedes cambiar esto al que quieras
else
    DEFAULT_TEMA=$(cat "$SCRIPTS_DIR/tema-actual.txt")
fi

# Si tampoco existe ese tema, salir
[ ! -d "$TEMAS_DIR/$DEFAULT_TEMA" ] && exit

TEMA_PATH="$TEMAS_DIR/$DEFAULT_TEMA"
FONDO="$TEMA_PATH/fondo.png"
GTK_FILE="$TEMA_PATH/gtk.txt"
ICON_FILE="$TEMA_PATH/icon.txt"


# Leer nombre de tema GTK e iconos
GTK_THEME=$(cat "$GTK_FILE" 2>/dev/null || echo "my-wal-theme")
ICON_THEME=$(cat "$ICON_FILE" 2>/dev/null || echo "Tela-circle-blue")

# Cambiar fondo
pkill swaybg
swaybg -i "$FONDO" --mode fill &

# Cambiar tema GTK
gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME"

# Cambiar tema de iconos
gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME"

# Aplicar wal
#wal -i "$FONDO"
