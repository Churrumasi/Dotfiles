#!/usr/bin/env bash
# adapta tema para i3
# usa: colocar en ~/.config/scripts/restaurar-tema-i3.sh y darle permisos +x

set -u

TEMAS_DIR="$HOME/.config/temas"
SCRIPTS_DIR="$HOME/.config/scripts"

# Tema por defecto si no existe registro
if [ ! -f "$SCRIPTS_DIR/tema-actual.txt" ]; then
    DEFAULT_TEMA="Lynette"
else
    DEFAULT_TEMA=$(cat "$SCRIPTS_DIR/tema-actual.txt")
fi

# Si el tema no existe, salir silenciosamente
[ ! -d "$TEMAS_DIR/$DEFAULT_TEMA" ] && exit 0

TEMA_PATH="$TEMAS_DIR/$DEFAULT_TEMA"
FONDO_IMG="$TEMA_PATH/fondo.png"
FONDO_VIDEO="$TEMA_PATH/fondo.mp4"
GTK_FILE="$TEMA_PATH/gtk.txt"
ICON_FILE="$TEMA_PATH/icon.txt"
DUNST="$TEMA_PATH/dunstrc"
ROFI_THEME_FILE="$TEMA_PATH/mitema.rasi"

# Leer tema GTK e iconos (valores por defecto si no existen)
GTK_THEME=$(cat "$GTK_FILE" 2>/dev/null || echo "my-wal-theme")
ICON_THEME=$(cat "$ICON_FILE" 2>/dev/null || echo "Tela-circle-blue")

### Limpiar fondos/players anteriores ###
pkill feh        2>/dev/null || true
pkill xwinwrap   2>/dev/null || true
pkill mpv        2>/dev/null || true
pkill gifview    2>/dev/null || true
pkill swaybg     2>/dev/null || true

### Aplicar fondo ###
if [[ -f "$FONDO_VIDEO" ]]; then
    # Fondo animado con xwinwrap + mpv
    sleep 0.3
    xwinwrap -ov -g 1920x1080+0+0 -- \
        mpv --no-audio --loop --no-osc --osd-level=0 --no-osd-bar \
            --really-quiet --no-input-default-bindings --wid=%WID \
            "$FONDO_VIDEO" &>/dev/null &
elif [[ -f "$FONDO_IMG" ]]; then
    # Fondo estático con feh
    feh --bg-fill "$FONDO_IMG"
fi

### APLICAR TEMA GTK E ICONOS (i3 FIX REAL) ###

GTK3_DIR="$HOME/.config/gtk-3.0"
GTK3_FILE="$GTK3_DIR/settings.ini"
GTK2_FILE="$HOME/.gtkrc-2.0"

mkdir -p "$GTK3_DIR"

# GTK 3
cat > "$GTK3_FILE" <<EOF
[Settings]
gtk-theme-name=$GTK_THEME
gtk-icon-theme-name=$ICON_THEME
gtk-font-name=Sans 10
gtk-cursor-theme-name=Adwaita
gtk-application-prefer-dark-theme=false
EOF

# GTK 2
cat > "$GTK2_FILE" <<EOF
gtk-theme-name="$GTK_THEME"
gtk-icon-theme-name="$ICON_THEME"
gtk-font-name="Sans 10"
gtk-cursor-theme-name="Adwaita"
EOF

### Configurar Dunst (si existe) ###
if [[ -f "$DUNST" ]]; then
    mkdir -p "$HOME/.config/dunst"
    cp "$DUNST" "$HOME/.config/dunst/dunstrc"
    pkill dunst 2>/dev/null || true
    dunst &>/dev/null &
fi

### Aplicar tema de Rofi (si existe) ###
if [[ -f "$ROFI_THEME_FILE" ]]; then
    mkdir -p "$HOME/.config/rofi/colors" "$HOME/.config/rofi/themes"
    cp "$ROFI_THEME_FILE" "$HOME/.config/rofi/colors/mitema.rasi"
    cp "$ROFI_THEME_FILE" "$HOME/.config/rofi/themes/mitema.rasi"
fi

### Aplicar colores Pywal ###
if command -v wal >/dev/null 2>&1; then
    # si hay fondo, úsalo; si no, wal fallará silenciosamente
    if [[ -f "$FONDO_IMG" ]]; then
        wal -i "$FONDO_IMG" >/dev/null 2>&1 || true
    else
        wal -q -a 80 >/dev/null 2>&1 || true
    fi
fi

### Reiniciar/relanzar compositor si existe (picom/compton) ###
if pgrep -x picom >/dev/null 2>&1; then
    pkill -x picom 2>/dev/null || true
    sleep 0.2
    picom &>/dev/null &
elif pgrep -x compton >/dev/null 2>&1; then
    pkill -x compton 2>/dev/null || true
    sleep 0.2
    compton &>/dev/null &
fi

### Reiniciar/relanzar Polybar (intentos) ###
# Si usas polybar y tienes barras con nombres no estándar, adapta esta sección.
if pgrep -x polybar >/dev/null 2>&1; then
    pkill -x polybar 2>/dev/null || true
    sleep 0.2
    # Intentos de relanzar barras comunes; si tu polybar usa nombres distintos, modifica aquí:
    if command -v polybar >/dev/null 2>&1; then
        # intenta relanzar una barra llamada "main" y "tray" (silencioso si falla)
        polybar --reload main &>/dev/null || true
        polybar --reload tray &>/dev/null || true
    fi
fi

### Recargar config de i3 (no reinicia, solo recarga) ###
if command -v i3-msg >/dev/null 2>&1; then
    i3-msg reload >/dev/null 2>&1 || true
fi

### Notificar restauración ###
notify-send "Tema restaurado" "Tema activo: $DEFAULT_TEMA"

exit 0
