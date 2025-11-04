#!/bin/bash

TEMAS_DIR="$HOME/.config/temas"
SCRIPTS_DIR="$HOME/.config/scripts"

# Tema por defecto si no existe registro
if [ ! -f "$SCRIPTS_DIR/tema-actual.txt" ]; then
    DEFAULT_TEMA="Lynette"
else
    DEFAULT_TEMA=$(cat "$SCRIPTS_DIR/tema-actual.txt")
fi

# Si el tema no existe, salir
[ ! -d "$TEMAS_DIR/$DEFAULT_TEMA" ] && exit

TEMA_PATH="$TEMAS_DIR/$DEFAULT_TEMA"
FONDO_IMG="$TEMA_PATH/fondo.png"
FONDO_VIDEO="$TEMA_PATH/fondo.mp4"
GTK_FILE="$TEMA_PATH/gtk.txt"
ICON_FILE="$TEMA_PATH/icon.txt"
DUNST="$TEMA_PATH/dunstrc"
ROFI_THEME_FILE="$TEMA_PATH/mitema.rasi"

# Leer tema GTK e iconos
GTK_THEME=$(cat "$GTK_FILE" 2>/dev/null || echo "my-wal-theme")
ICON_THEME=$(cat "$ICON_FILE" 2>/dev/null || echo "Tela-circle-blue")

### Limpiar fondos anteriores ###
pkill feh 2>/dev/null
pkill xwinwrap 2>/dev/null
pkill mpv 2>/dev/null
pkill gifview 2>/dev/null
pkill swaybg 2>/dev/null

### Aplicar fondo ###
if [[ -f "$FONDO_VIDEO" ]]; then
    # Fondo animado
    sleep 0.5
    xwinwrap -ov -g 1920x1080+0+0 -- \
        mpv --no-audio --loop --no-osc --osd-level=0 --no-osd-bar \
        --really-quiet --no-input-default-bindings --wid=%WID \
        "$FONDO_VIDEO" &
else
    # Fondo estático
    feh --bg-fill "$FONDO_IMG"
fi

### Aplicar tema GTK e iconos ###
if command -v lxappearance >/dev/null 2>&1; then
    # LXDE guarda los temas aquí
    sed -i "/^gtk-theme-name=/c\gtk-theme-name=\"$GTK_THEME\"" ~/.config/gtk-3.0/settings.ini 2>/dev/null
    sed -i "/^gtk-icon-theme-name=/c\gtk-icon-theme-name=\"$ICON_THEME\"" ~/.config/gtk-3.0/settings.ini 2>/dev/null
    sed -i "/^gtk-theme-name=/c\gtk-theme-name=\"$GTK_THEME\"" ~/.gtkrc-2.0 2>/dev/null
    sed -i "/^gtk-icon-theme-name=/c\gtk-icon-theme-name=\"$ICON_THEME\"" ~/.gtkrc-2.0 2>/dev/null
fi

### Reiniciar panel de LXDE ###
pkill lxpanel
lxpanel --profile LXDE &

### Configurar Dunst (si existe) ###
if [[ -f "$DUNST" ]]; then
    cp "$DUNST" ~/.config/dunst/dunstrc
    pkill dunst && dunst &
fi

### Aplicar tema de Rofi (si existe) ###
if [[ -f "$ROFI_THEME_FILE" ]]; then
    mkdir -p ~/.config/rofi/colors
    cp "$ROFI_THEME_FILE" ~/.config/rofi/colors/mitema.rasi
fi

### Aplicar colores Pywal ###
if command -v wal >/dev/null 2>&1; then
    wal -i "$FONDO_IMG" >/dev/null 2>&1
fi

### Notificar restauración ###
notify-send "Tema restaurado" "Tema activo: $DEFAULT_TEMA"
