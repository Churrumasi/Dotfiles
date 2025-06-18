#!/bin/bash

PIDFILE="/tmp/ydotool_autoclicker.pid"

# Comprobar si el daemon ydotoold está corriendo
if ! pgrep -x "ydotoold" > /dev/null; then
    echo "ydotoold no está corriendo. Intentando iniciar..."
    if systemctl status ydotoold.service &>/dev/null; then
        sudo systemctl start ydotoold.service
        sleep 1
        if ! pgrep -x "ydotoold" > /dev/null; then
            notify-send "Autoclicker" "Fallo al iniciar ydotoold"
            exit 1
        fi
    else
        notify-send "Autoclicker" "El servicio ydotoold no existe"
        exit 1
    fi
fi

# Función para iniciar el autoclicker
start_autoclicker() {
    while true; do
        ydotool click 1
        sleep 0.2
    done
}

# Si el autoclicker ya está corriendo, lo detiene
if [[ -f "$PIDFILE" ]]; then
    PID=$(cat "$PIDFILE")
    if ps -p "$PID" > /dev/null; then
        kill "$PID"
        rm "$PIDFILE"
        notify-send "Autoclicker" "Desactivado"
        exit 0
    else
        rm "$PIDFILE"
    fi
fi

# Si no está corriendo, lo inicia
start_autoclicker & disown
echo $! > "$PIDFILE"
notify-send "Autoclicker" "Activado"

