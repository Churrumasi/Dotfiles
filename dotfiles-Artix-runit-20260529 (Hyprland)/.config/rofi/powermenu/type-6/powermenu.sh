#!/usr/bin/env bash

dir="$HOME/.config/rofi/powermenu/type-6"
theme='style-6'

uptime="$(uptime -p | sed 's/^up //')"
host="$(hostname)"

hibernate=''
shutdown=''
reboot=''
lock=''
suspend=''
logout=''
yes=''
no=''

# Detectar sesión actual
session="$(loginctl show-session "$(loginctl | awk "/$(whoami)/ {print \$1; exit}")" -p Type --value)"

rofi_cmd() {
    rofi -dmenu \
        -p " $USER@$host" \
        -mesg " Tiempo activo: $uptime" \
        -theme "${dir}/${theme}.rasi"
}

confirm_cmd() {
    rofi -dmenu \
        -p 'Confirmación' \
        -mesg '¿Estás seguro?' \
        -theme-str 'window {location: center; anchor: center; fullscreen: false; width: 350px;}' \
        -theme-str 'mainbox {orientation: vertical; children: [ "message", "listview" ];}' \
        -theme-str 'listview {columns: 2; lines: 1;}' \
        -theme-str 'element-text {horizontal-align: 0.5;}' \
        -theme-str 'textbox {horizontal-align: 0.5;}' \
        -theme "${dir}/${theme}.rasi"
}

confirm_exit() {
    printf '%s\n%s\n' "$yes" "$no" | confirm_cmd
}

run_rofi() {
    printf '%s\n%s\n%s\n%s\n%s\n%s\n' \
        "$lock" \
        "$suspend" \
        "$logout" \
        "$hibernate" \
        "$reboot" \
        "$shutdown" | rofi_cmd
}

# Compatibilidad Artix + runit
poweroff_cmd() {
    loginctl poweroff || doas poweroff || sudo poweroff
}

reboot_cmd() {
    loginctl reboot || doas reboot || sudo reboot
}

hibernate_cmd() {
    loginctl hibernate || doas zzz || sudo zzz
}

suspend_cmd() {
    loginctl suspend || doas zzz || sudo zzz
}

logout_cmd() {
    case "$session" in
        wayland)
            if command -v hyprctl >/dev/null 2>&1; then
                hyprctl dispatch exit
            fi
            ;;
        x11)
            pkill -KILL -u "$USER"
            ;;
    esac
}

lock_cmd() {
    if command -v hyprlock >/dev/null 2>&1; then
        hyprlock
    elif command -v gtklock >/dev/null 2>&1; then
        gtklock
    elif command -v swaylock >/dev/null 2>&1; then
        swaylock
    fi
}

run_cmd() {
    selected="$(confirm_exit)"

    if [[ "$selected" == "$yes" ]]; then
        case "$1" in
            --shutdown)
                poweroff_cmd
                ;;

            --reboot)
                reboot_cmd
                ;;

            --hibernate)
                hibernate_cmd
                ;;

            --suspend)
                if command -v hyprlock >/dev/null 2>&1; then
                    hyprlock &
                    sleep 1
                fi

                suspend_cmd
                ;;

            --logout)
                logout_cmd
                ;;
        esac
    else
        exit 0
    fi
}

chosen="$(run_rofi)"

case "$chosen" in
    "$shutdown")
        run_cmd --shutdown
        ;;

    "$reboot")
        run_cmd --reboot
        ;;

    "$hibernate")
        run_cmd --hibernate
        ;;

    "$lock")
        lock_cmd
        ;;

    "$suspend")
        run_cmd --suspend
        ;;

    "$logout")
        run_cmd --logout
        ;;
esac