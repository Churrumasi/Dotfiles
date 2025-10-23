#!/usr/bin/env bash
set -euo pipefail

# --- Configuración ---
TEMAS_DIR="$HOME/.config/temas"
SCRIPTS_DIR="$HOME/.config/scripts"
LXDE_CONF="$HOME/.config/lxsession/LXDE/desktop.conf"

# --- Seleccionar tema con rofi ---
TEMA=$(ls "$TEMAS_DIR" | while read -r dir; do
    echo -en "$dir\x00icon\x1f$TEMAS_DIR/$dir/fondo.png\n"
done | rofi -dmenu \
    -theme ~/.config/rofi/launchers/type-2/style-2.rasi \
    -p "Temas")

[ -z "${TEMA:-}" ] && exit 0

TEMA_PATH="$TEMAS_DIR/$TEMA"
FONDO_IMG="$TEMA_PATH/fondo.png"
DUNST="$TEMA_PATH/dunstrc"
GTK_FILE="$TEMA_PATH/gtk.txt"
ICON_FILE="$TEMA_PATH/icon.txt"
ROFI_THEME_FILE="$TEMA_PATH/mitema.rasi"

GTK_THEME=$(cat "$GTK_FILE" 2>/dev/null || echo "Adwaita")
ICON_THEME=$(cat "$ICON_FILE" 2>/dev/null || echo "Papirus")

mkdir -p "$SCRIPTS_DIR"

# --- Funciones ---
log() { printf '%s\n' "$*"; }

kill_previous_wallpapers() {
    # matar cualquier fondo anterior (imagen o video)
    pkill -9 feh 2>/dev/null || true
    pkill -9 xwinwrap 2>/dev/null || true
    pkill -9 mpv 2>/dev/null || true
    pkill -9 gifview 2>/dev/null || true
    sleep 0.4
}

set_static_wallpaper() {
    local img="$1"
    [[ -f "$img" ]] || return
    feh --bg-fill "$img" &
}

set_video_wallpaper_per_monitor() {
    local video="$1"
    # lista de monitores con su geometría (ej: 1920x1080+0+0)
    mapfile -t mons < <(xrandr --query | grep " connected" | grep -oP '[0-9]+x[0-9]+\+[0-9]+\+[0-9]+')
    if [[ ${#mons[@]} -eq 0 ]]; then
        xwinwrap -ov -fs -- mpv --no-audio --loop --no-osc --osd-level=0 --no-osd-bar --really-quiet --no-input-default-bindings --wid=%WID "$video" &
        return
    fi

    for geom in "${mons[@]}"; do
        xwinwrap -ov -g "$geom" -- mpv --no-audio --loop --no-osc --osd-level=0 --no-osd-bar \
        --really-quiet --no-input-default-bindings --wid=%WID "$video" &
        sleep 0.1
    done
}

# --- Dunst ---
if [[ -f "$DUNST" ]]; then
    mkdir -p ~/.config/dunst
    cp -f "$DUNST" ~/.config/dunst/dunstrc
    pkill dunst 2>/dev/null || true
    dunst & disown
fi

# --- Detectar video del tema ---
VIDEO=""
if [[ -f "$TEMA_PATH/fondo.mp4" ]]; then
    VIDEO="$TEMA_PATH/fondo.mp4"
else
    VIDEO=$(find "$TEMA_PATH" -maxdepth 1 -type f -iname '*.mp4' | head -n1 || true)
fi

# --- Cambiar GTK/Iconos ---
mkdir -p "$(dirname "$LXDE_CONF")"
if [[ -f "$LXDE_CONF" ]]; then
    sed -i "s|^sNet/ThemeName=.*|sNet/ThemeName=$GTK_THEME|" "$LXDE_CONF" || echo "sNet/ThemeName=$GTK_THEME" >> "$LXDE_CONF"
    sed -i "s|^sNet/IconThemeName=.*|sNet/IconThemeName=$ICON_THEME|" "$LXDE_CONF" || echo "sNet/IconThemeName=$ICON_THEME" >> "$LXDE_CONF"
else
    cat > "$LXDE_CONF" <<EOF
[GTK]
sNet/ThemeName=$GTK_THEME
sNet/IconThemeName=$ICON_THEME
EOF
fi

# --- Fondo (con pkill preventivo) ---
kill_previous_wallpapers

if [[ -n "${VIDEO:-}" && -f "$VIDEO" ]]; then
    log "Usando fondo animado: $VIDEO"
    set_video_wallpaper_per_monitor "$VIDEO"
else
    if [[ -f "$FONDO_IMG" ]]; then
        log "Usando fondo estático: $FONDO_IMG"
        set_static_wallpaper "$FONDO_IMG"
    else
        log "⚠️  No se encontró fondo para el tema $TEMA"
    fi
fi

# --- Rofi ---
if [[ -f "$ROFI_THEME_FILE" ]]; then
    mkdir -p ~/.config/rofi/colors
    cp -f "$ROFI_THEME_FILE" ~/.config/rofi/colors/mitema.rasi
fi

# --- Wal (solo si hay imagen y wal está instalado) ---
#if command -v wal &>/dev/null && [[ -z "${VIDEO:-}" && -f "$FONDO_IMG" ]]; then
    wal -i "$FONDO_IMG"
#fi

# --- Recargar panel LXDE ---
pkill lxpanel 2>/dev/null || true
sleep 0.8
lxpanel --profile LXDE & disown

# --- Notificar ---
echo "$TEMA" > "$SCRIPTS_DIR/tema-actual.txt"
notify-send "🎨 Tema cambiado" "Tema activo: $TEMA"

log "✅ Tema aplicado correctamente: $TEMA"
