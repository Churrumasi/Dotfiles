#!/bin/bash
# Toggle de grabación de pantalla en X11 (LXDE) usando ffmpeg.
# Uso:
#  ./grabar_pantalla.sh                -> graba pantalla completa con audio del sistema (si hay)
#  ./grabar_pantalla.sh --area         -> seleccionar región con slop
#  ./grabar_pantalla.sh --mic          -> graba pantalla + micrófono + audio del sistema
#  ./grabar_pantalla.sh --mic-only     -> graba pantalla + solo micrófono
#  ./grabar_pantalla.sh --no-audio     -> graba pantalla sin sonido
#
# Ejecuta de nuevo mientras graba → detiene la grabación

set -u

DIR="$HOME/Videos"
FILENAME="grabacion_$(date +%Y-%m-%d_%H-%M-%S).mp4"
FULLPATH="$DIR/$FILENAME"
PIDFILE="$HOME/.cache/screenrec_ffmpeg.pid"
LOGFILE="$HOME/.cache/screenrec_ffmpeg.log"
FRAMERATE=30

mkdir -p "$DIR"

# --- TOGGLE: detener grabación si ya hay una en curso ---
if [ -f "$PIDFILE" ]; then
    PID=$(cat "$PIDFILE")
    if kill -0 "$PID" 2>/dev/null; then
        kill "$PID"
        sleep 0.3
        rm -f "$PIDFILE"
        notify-send "✅ Grabación detenida" "Archivo: $FULLPATH"
        exit 0
    else
        rm -f "$PIDFILE"
    fi
fi

# --- Parsear argumentos ---
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

# --- Selección de área ---
if $AREA_MODE; then
    if ! command -v slop >/dev/null 2>&1; then
        notify-send "❌ slop no encontrado" "Instala 'slop' con: pacman -S slop"
        exit 1
    fi
    read X Y W H < <(slop -f "%x %y %w %h")
    if [ -z "$W" ] || [ -z "$H" ]; then
        notify-send "❌ Región inválida" "No se seleccionó una región."
        exit 1
    fi
    VIDEO_SIZE="${W}x${H}"
    INPUT_DISPLAY=":0.0+${X},${Y}"
else
    if command -v xdpyinfo >/dev/null 2>&1; then
        VIDEO_SIZE=$(xdpyinfo | awk '/dimensions:/ {print $2}')
    else
        VIDEO_SIZE=$(xrandr | grep '*' | awk '{print $1}' | head -n1)
    fi
    INPUT_DISPLAY=":0.0"
fi

# --- Opciones de audio ---
AUDIO_OPTS=()
if ! $NO_AUDIO; then
    if command -v pactl >/dev/null 2>&1 && pactl info >/dev/null 2>&1; then
        if $MIC_MODE; then
            # Combinar micrófono + monitor del sistema
            MONITOR_SRC=$(pactl list short sources | awk '/monitor/{print $2; exit}')
            MIC_SRC=$(pactl list short sources | awk '!/monitor/{print $2; exit}')
            AUDIO_OPTS=(-f pulse -i "$MONITOR_SRC" -f pulse -i "$MIC_SRC" \
                -filter_complex "amix=inputs=2:duration=longest" -ac 2)
        elif $MIC_ONLY_MODE; then
            # Solo micrófono
            MIC_SRC=$(pactl list short sources | awk '!/monitor/{print $2; exit}')
            AUDIO_OPTS=(-f pulse -i "$MIC_SRC" -ac 2)
        else
            # Solo audio del sistema
            AUDIO_OPTS=(-f pulse -ac 2 -i default)
        fi
    fi
fi

# --- Comando ffmpeg ---
FFMPEG_CMD=(ffmpeg -y -video_size "$VIDEO_SIZE" -framerate "$FRAMERATE" -f x11grab -i "$INPUT_DISPLAY")
if [ ${#AUDIO_OPTS[@]} -gt 0 ]; then
    FFMPEG_CMD+=("${AUDIO_OPTS[@]}")
fi
FFMPEG_CMD+=(-c:v libx264 -preset ultrafast -crf 18 -pix_fmt yuv420p -c:a aac -b:a 128k "$FULLPATH")

# --- Ejecutar ffmpeg ---
nohup "${FFMPEG_CMD[@]}" >"$LOGFILE" 2>&1 &
PID=$!
sleep 0.2

if kill -0 "$PID" 2>/dev/null; then
    echo "$PID" > "$PIDFILE"
    MODE="pantalla"
    if $MIC_MODE; then MODE="pantalla + micrófono + sistema"; fi
    if $MIC_ONLY_MODE; then MODE="pantalla + micrófono"; fi
    if $NO_AUDIO; then MODE="solo pantalla (sin audio)"; fi
    notify-send "🎥 Grabación iniciada" "Modo: $MODE\nArchivo: $FILENAME"
    exit 0
else
    notify-send "❌ Error al iniciar grabación" "Revisa $LOGFILE"
    exit 1
fi
	