#!/usr/bin/env bash
set -euo pipefail

#############################################
# CONFIG
#############################################

TEMAS_DIR="$HOME/.config/temas"
SCRIPTS_DIR="$HOME/.config/scripts"

POLYBAR_DIR="$HOME/.config/polybar"
KITTY_DIR="$HOME/.config/kitty"
ALACRITTY_DIR="$HOME/.config/alacritty"

mkdir -p "$SCRIPTS_DIR"
mkdir -p "$POLYBAR_DIR"
mkdir -p "$KITTY_DIR"
mkdir -p "$ALACRITTY_DIR"

#############################################
# SELECCIONAR TEMA
#############################################

TEMA=$(ls "$TEMAS_DIR" | while read -r dir; do
    echo -en "$dir\x00icon\x1f$TEMAS_DIR/$dir/fondo.png\n"
done | rofi -dmenu \
    -theme ~/.config/rofi/launchers/type-2/style-2.rasi \
    -p "Temas")

[ -z "${TEMA:-}" ] && exit 0

TEMA_PATH="$TEMAS_DIR/$TEMA"

#############################################
# ARCHIVOS DEL TEMA
#############################################

FONDO_IMG="$TEMA_PATH/fondo.png"
VIDEO="$TEMA_PATH/fondo.mp4"

DUNST="$TEMA_PATH/dunstrc"
ROFI_THEME="$TEMA_PATH/mitema.rasi"

GTK_FILE="$TEMA_PATH/gtk.txt"
ICON_FILE="$TEMA_PATH/icon.txt"

POLYBAR_THEME="$TEMA_PATH/polybar.ini"
KITTY_THEME="$TEMA_PATH/colors-kitty.conf"
ALACRITTY_THEME="$TEMA_PATH/alacritty.toml"

GTK_THEME=$(cat "$GTK_FILE" 2>/dev/null || echo "Adwaita")
ICON_THEME=$(cat "$ICON_FILE" 2>/dev/null || echo "Papirus")

#############################################
# FUNCIONES
#############################################

log() { printf '%s\n' "$*"; }

kill_previous_wallpapers() {
    pkill -9 feh 2>/dev/null || true
    pkill -9 xwinwrap 2>/dev/null || true
    pkill -9 mpv 2>/dev/null || true
    sleep 0.4
}

#############################################
# FONDO
#############################################

set_static_wallpaper() {
    feh --bg-fill "$1" &
}

set_video_wallpaper_per_monitor() {

    mapfile -t mons < <(xrandr --query | grep " connected" | grep -oP '[0-9]+x[0-9]+\+[0-9]+\+[0-9]+')

    if [[ ${#mons[@]} -eq 0 ]]; then
        xwinwrap -ov -fs -- mpv --no-audio --loop --no-osc \
        --osd-level=0 --no-osd-bar --really-quiet \
        --no-input-default-bindings --wid=%WID "$1" &
        return
    fi

    for geom in "${mons[@]}"; do
        xwinwrap -ov -g "$geom" -- mpv --no-audio --loop \
        --no-osc --osd-level=0 --no-osd-bar \
        --really-quiet --no-input-default-bindings \
        --wid=%WID "$1" &
        sleep 0.1
    done
}

#############################################
# DUNST
#############################################

if [[ -f "$DUNST" ]]; then
    mkdir -p ~/.config/dunst
    cp -f "$DUNST" ~/.config/dunst/dunstrc

    pkill dunst 2>/dev/null || true
    dunst & disown
fi

#############################################
# ROFI
#############################################

if [[ -f "$ROFI_THEME" ]]; then
    mkdir -p ~/.config/rofi/colors
    cp -f "$ROFI_THEME" ~/.config/rofi/colors/mitema.rasi
fi

#############################################
# KITTY
#############################################

if [[ -f "$KITTY_THEME" ]]; then
    cp -f "$KITTY_THEME" "$KITTY_DIR/colors-kitty.conf"
    log "🐱 Kitty theme aplicado"
fi

#############################################
# ALACRITTY
#############################################

if [[ -f "$ALACRITTY_THEME" ]]; then
    cp -f "$ALACRITTY_THEME" "$ALACRITTY_DIR/alacritty.toml"
    log "🐱 Kitty theme aplicado"
fi


#############################################
# POLYBAR
#############################################

if [[ -f "$POLYBAR_THEME" ]]; then

    cp -f "$POLYBAR_THEME" "$POLYBAR_DIR/config.ini"

    log "🔄 Reiniciando polybar"

    pkill polybar 2>/dev/null || true
    sleep 0.5

    polybar  & 
fi

#############################################
# WAL
#############################################

if command -v wal &>/dev/null && [[ -f "$FONDO_IMG" ]]; then
    wal -i "$FONDO_IMG"
fi

#############################################
# FONDO
#############################################

kill_previous_wallpapers

if [[ -f "$VIDEO" ]]; then
    log "🎥 Fondo animado"
    set_video_wallpaper_per_monitor "$VIDEO"
else

    if [[ -f "$FONDO_IMG" ]]; then
        log "🖼 Fondo estático"
        set_static_wallpaper "$FONDO_IMG"
    else
        log "⚠ No se encontró fondo"
    fi

fi
walcord &
#############################################
# NOTIFICACIÓN
#############################################

echo "$TEMA" > "$SCRIPTS_DIR/tema-actual.txt"

notify-send "🎨 Tema cambiado" "Tema activo: $TEMA"

log "✅ Tema aplicado correctamente: $TEMA"
