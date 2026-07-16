#!/bin/bash

set -euo pipefail

# =========================
# Configuración
# =========================
DIR="$HOME/Videos"
FRAMERATE=60

TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
FILENAME="grabacion_${TIMESTAMP}.mp4"
FULLPATH="$DIR/$FILENAME"

PIDFILE="$HOME/.cache/screenrec_ffmpeg.pid"
OUTFILE="$HOME/.cache/screenrec_ffmpeg.out"
LOGFILE="$HOME/.cache/screenrec_ffmpeg.log"

mkdir -p "$DIR"
mkdir -p "$HOME/.cache"

# =========================
# Toggle detener grabación
# =========================
if [[ -f "$PIDFILE" ]]; then
    PID=$(cat "$PIDFILE")

    if kill -0 "$PID" 2>/dev/null; then
        pkill -INT -P "$PID" 2>/dev/null || true
        kill -INT "$PID"

        sleep 1

        RECORDED_FILE=$(cat "$OUTFILE" 2>/dev/null || echo "desconocido")

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
        --area) AREA_MODE=true ;;
        --mic) MIC_MODE=true ;;
        --mic-only) MIC_ONLY_MODE=true ;;
        --no-audio) NO_AUDIO=true ;;
    esac
done

# =========================
# Pantalla / región
# =========================
if $AREA_MODE; then

    if ! command -v slop >/dev/null; then
        notify-send "Error" "Instala slop"
        exit 1
    fi

    read -r X Y W H < <(slop -f "%x %y %w %h")

    [[ -z "${W:-}" ]] && exit 1

    VIDEO_SIZE="${W}x${H}"
    DISPLAY_INPUT="${DISPLAY}+${X},${Y}"

else

    VIDEO_SIZE=$(xrandr | grep '*' | head -n1 | awk '{print $1}')
    DISPLAY_INPUT="${DISPLAY}"

fi

# =========================
# Detectar audio
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

if ! $NO_AUDIO && command -v pactl >/dev/null; then

    MONITOR_SRC=$(get_monitor_source || true)
    MIC_SRC=$(get_mic_source || true)

    if $MIC_MODE; then

        if [[ -n "$MONITOR_SRC" && -n "$MIC_SRC" ]]; then

            AUDIO_OPTS=(
                -f pulse -i "$MONITOR_SRC"
                -f pulse -i "$MIC_SRC"
                -filter_complex "amix=inputs=2:duration=longest"
                -ac 2
            )

        fi

    elif $MIC_ONLY_MODE; then

        if [[ -n "$MIC_SRC" ]]; then
            AUDIO_OPTS=(
                -f pulse -i "$MIC_SRC"
                -ac 2
            )
        fi

    else

        # SOLO AUDIO DEL SISTEMA
        if [[ -n "$MONITOR_SRC" ]]; then
            AUDIO_OPTS=(
                -f pulse -i "$MONITOR_SRC"
                -ac 2
            )
        fi

    fi
fi

# =========================
# FFmpeg
# =========================
FFMPEG_CMD=(
    ffmpeg
    -y

    -f x11grab
    -framerate "$FRAMERATE"
    -video_size "$VIDEO_SIZE"
    -i "$DISPLAY_INPUT"
)

if [[ ${#AUDIO_OPTS[@]} -gt 0 ]]; then
    FFMPEG_CMD+=("${AUDIO_OPTS[@]}")
fi

FFMPEG_CMD+=(
    -c:v libx264
    -preset veryfast
    -crf 20

    -pix_fmt yuv420p

    -c:a aac
    -b:a 192k

    "$FULLPATH"
)

# =========================
# Ejecutar
# =========================
echo "$FULLPATH" > "$OUTFILE"

nohup "${FFMPEG_CMD[@]}" \
    > "$LOGFILE" 2>&1 &

PID=$!

sleep 1

if kill -0 "$PID" 2>/dev/null; then

    echo "$PID" > "$PIDFILE"

    MODE="Pantalla"

    $MIC_MODE && MODE="Pantalla + micrófono + sistema"
    $MIC_ONLY_MODE && MODE="Pantalla + micrófono"
    $NO_AUDIO && MODE="Pantalla sin audio"

    notify-send "🎥 Grabación iniciada" \
        "$MODE"

else

    notify-send "❌ Error" \
        "Revisa: $LOGFILE"

    exit 1
fi