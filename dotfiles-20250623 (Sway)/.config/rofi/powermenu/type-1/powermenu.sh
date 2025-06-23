#!/usr/bin/env bash

## Autor : Aditya Shakya (adi1090x)
## Adaptación : ChatGPT (OpenAI)
#
## Rofi   : Menú de Energía para Sway
#
## Estilos disponibles
#
## style-1   style-2   style-3   style-4   style-5

# Tema actual
dir="$HOME/.config/rofi/powermenu/type-1"
theme='style-1'

# Comandos
uptime="$(uptime -p | sed -e 's/up //g')"
host=$(hostname)

# Opciones
shutdown=' Apagar'
reboot=' Reiniciar'
lock=' Bloquear'
suspend=' Suspender'
logout=' Cerrar sesión'
yes=' Sí'
no=' No'

# Comando Rofi
rofi_cmd() {
	rofi -dmenu \
		-p "$host" \
		-mesg "Tiempo encendido: $uptime" \
		-theme "${dir}/${theme}.rasi"
}

# Comando de Confirmación
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

# Preguntar confirmación
confirm_exit() {
	echo -e "$yes\n$no" | confirm_cmd
}

# Mostrar el menú
run_rofi() {
	echo -e "$lock\n$suspend\n$logout\n$reboot\n$shutdown" | rofi_cmd
}

# Ejecutar Comando
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
				mpc -q pause
				amixer set Master mute
				systemctl suspend
				;;
			--logout)
				swaymsg exit
				;;
		esac
	else
		exit 0
	fi
}

# Acciones
chosen="$(run_rofi)"
case ${chosen} in
    $shutdown)
		run_cmd --shutdown
        ;;
    $reboot)
		run_cmd --reboot
        ;;
    $lock)
		if command -v swaylock >/dev/null 2>&1; then
			swaylock-fancy
		elif command -v i3lock >/dev/null 2>&1; then
			i3lock
		fi
        ;;
    $suspend)
		run_cmd --suspend
        ;;
    $logout)
		run_cmd --logout
        ;;
esac
