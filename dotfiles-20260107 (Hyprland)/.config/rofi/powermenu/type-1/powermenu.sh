#!/usr/bin/env bash

## Autor original : Aditya Shakya (adi1090x)
## Adaptado a Hyprland por ChatGPT

# Ruta al tema de Rofi
dir="$HOME/.config/rofi/powermenu/type-1"
theme='style-1'

# Datos del sistema
uptime="$(uptime -p | sed -e 's/up //g')"
host=$(hostname)

# Opciones del menú
shutdown=' Apagar'
reboot=' Reiniciar'
lock=' Bloquear'
suspend=' Suspender'
logout=' Cerrar sesión'
yes=' Sí'
no=' No'

# Función para lanzar Rofi con el menú principal
rofi_cmd() {
	rofi -dmenu \
		-p "$host" \
		-mesg "Tiempo encendido: $uptime" \
		-theme "${dir}/${theme}.rasi"
}

# Función para confirmaciones
confirm_cmd() {
	rofi -theme-str 'window {location: center; anchor: center; fullscreen: false; width: 250px;}' \
		-theme-str 'mainbox {children: [ "message", "listview" ];}' \
		-theme-str 'listview {columns: 2; lines: 1;}' \
		-theme-str 'element-text {horizontal-align: 0.5;}' \
		-theme-str 'textbox {horizontal-align: 0.5;}' \
		-dmenu \
		-p 'Confirmación' \
		-mesg '¿Estás seguro?' \
		-theme "${dir}/${theme}.rasi"
}

# Pregunta de confirmación
confirm_exit() {
	echo -e "$yes\n$no" | confirm_cmd
}

# Mostrar menú principal
run_rofi() {
	echo -e "$lock\n$suspend\n$logout\n$reboot\n$shutdown" | rofi_cmd
}

# Ejecutar acciones con confirmación
run_cmd() {
	selected="$(confirm_exit)"
	if [[ "$selected" == "$yes" ]]; then
		case $1 in
			--shutdown)
				systemctl poweroff
				;;
			--reboot)
				systemctl reboot
				;;
			--suspend)
				mpc -q pause 2>/dev/null
				amixer set Master mute 2>/dev/null
				systemctl suspend
				;;
			--logout)
				hyprctl dispatch exit
				;;
		esac
	else
		exit 0
	fi
}

# Acción seleccionada
chosen="$(run_rofi)"
case ${chosen} in
    $shutdown)
		run_cmd --shutdown
        ;;
    $reboot)
		run_cmd --reboot
        ;;
    $lock)
	
		if command -v hyprlock >/dev/null 2>&1; then
			hyprlock
		elif command -v i3lock >/dev/null 2>&1; then
			i3lock
		else
			notify-send "🔒 Ningún lockscreen encontrado"
		fi
        ;;
    $suspend)
		run_cmd --suspend
        ;;
    $logout)
		run_cmd --logout
        ;;
esac
