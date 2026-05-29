#!/bin/bash

set -euo pipefail

# =========================
# Configuración
# =========================
DIR="$HOME/Videos"
CACHE_DIR="$HOME/.cache"

TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
FILENAME="grabacion_${TIMESTAMP}.mp4"
FULLPATH="$DIR/$FILENAME"

PIDFILE="$CACHE_DIR/wf-recorder.pid"
OUTFILE="$CACHE_DIR/wf-recorder.out"

FRAMERATE=60

mkdir -p "$DIR"
mkdir -p "$CACHE_DIR"

# =========================
# Toggle detener
# =========================
if [[ -f "$PIDFILE" ]]; then

    PID=$(cat "$PIDFILE")

    if kill -0 "$PID" 2>/dev/null; then

        kill -INT "$PID"

        sleep 1

        RECORDED_FILE=$(cat "$OUTFILE" 2>/dev/null || echo "Grabación finalizada")

        rm -f "$PIDFILE"

        notify-send "⏹ Grabación detenida" "$RECORDED_FILE"

        exit 0
    else
        rm -f "$PIDFILE"
    fi
fi

# =========================
# Argumentos
# =========================
AREA_MODE=false
MIC_MODE=false
MIC_ONLY_MODE=false
NO_AUDIO=false

for arg in "$@"; do
    case "$arg" in
        --area)
            AREA_MODE=true
            ;;
        --mic)
            MIC_MODE=true
            ;;
        --mic-only)
            MIC_ONLY_MODE=true
            ;;
        --no-audio)
            NO_AUDIO=true
            ;;
    esac
done

# =========================
# Región
# =========================
GEOMETRY=""

if $AREA_MODE; then

    if ! command -v slurp >/dev/null 2>&1; then
        notify-send "❌ Error" "Instala slurp"
        exit 1
    fi

    GEOMETRY=$(slurp)

    if [[ -z "$GEOMETRY" ]]; then
        notify-send "❌ Cancelado"
        exit 1
    fi
fi

# =========================
# Audio
# =========================
AUDIO_OPTS=()

get_monitor_source() {
    pactl get-default-sink 2>/dev/null | while read -r sink; do
        pactl list short sources | awk -v s="$sink" '
            $2 ~ s".monitor" {
                print $2
                exit
            }
        '
    done
}

get_mic_source() {
    pactl get-default-source 2>/dev/null
}

if ! $NO_AUDIO && command -v pactl >/dev/null 2>&1; then

    MONITOR_SRC=$(get_monitor_source || true)
    MIC_SRC=$(get_mic_source || true)

    if $MIC_MODE; then

        if [[ -n "$MONITOR_SRC" ]]; then
            AUDIO_OPTS+=(--audio="$MONITOR_SRC")
        fi

        if [[ -n "$MIC_SRC" ]]; then
            AUDIO_OPTS+=(--audio="$MIC_SRC")
        fi

    elif $MIC_ONLY_MODE; then

        if [[ -n "$MIC_SRC" ]]; then
            AUDIO_OPTS+=(--audio="$MIC_SRC")
        fi

    else

        # Solo audio del sistema
        if [[ -n "$MONITOR_SRC" ]]; then
            AUDIO_OPTS+=(--audio="$MONITOR_SRC")
        fi
    fi
fi

# =========================
# Comando wf-recorder
# =========================
CMD=(
    wf-recorder
    -f "$FULLPATH"

    -r "$FRAMERATE"

    -c libx264
    -p preset=veryfast
    -p crf=20
)

if [[ -n "$GEOMETRY" ]]; then
    CMD+=(-g "$GEOMETRY")
fi

if [[ ${#AUDIO_OPTS[@]} -gt 0 ]]; then
    CMD+=("${AUDIO_OPTS[@]}")
fi

# =========================
# Ejecutar
# =========================
echo "$FULLPATH" > "$OUTFILE"

"${CMD[@]}" >/dev/null 2>&1 &
PID=$!

sleep 1

if kill -0 "$PID" 2>/dev/null; then

    echo "$PID" > "$PIDFILE"

    MODE="Pantalla"

    $MIC_MODE && MODE="Pantalla + micrófono + sistema"
    $MIC_ONLY_MODE && MODE="Pantalla + micrófono"
    $NO_AUDIO && MODE="Pantalla sin audio"
    $AREA_MODE && MODE="$MODE (área)"

    notify-send "🎥 Grabación iniciada" "$MODE"

else

    notify-send "❌ Error" "wf-recorder no pudo iniciar"

    exit 1
fi