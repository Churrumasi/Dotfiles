#!/usr/bin/env bash

## Adaptado para Sway

dir="$HOME/.config/rofi/powermenu/type-6"
theme='style-6'

# Info
lastlogin="`last $USER | head -n1 | tr -s ' ' | cut -d' ' -f5,6,7`"
uptime="`uptime -p | sed -e 's/up //g'`"
host=`hostname`

# Opciones con iconos
hibernate=''
shutdown=''
reboot=''
lock=''
suspend=''
logout=''
yes=''
no=''

# Funciones
rofi_cmd() {
	rofi -dmenu \
		-p " $USER@$host" \
		-mesg " Uptime: $uptime" \
		-theme ${dir}/${theme}.rasi
}

confirm_cmd() {
	rofi -theme-str 'window {location: center; anchor: center; fullscreen: false; width: 350px;}' \
		-theme-str 'mainbox {orientation: vertical; children: [ "message", "listview" ];}' \
		-theme-str 'listview {columns: 2; lines: 1;}' \
		-theme-str 'element-text {horizontal-align: 0.5;}' \
		-theme-str 'textbox {horizontal-align: 0.5;}' \
		-dmenu \
		-p 'Confirmation' \
		-mesg 'Estas Seguro?' \
		-theme ${dir}/${theme}.rasi
}

confirm_exit() {
	echo -e "$yes\n$no" | confirm_cmd
}

run_rofi() {
	echo -e "$lock\n$suspend\n$logout\n$hibernate\n$reboot\n$shutdown" | rofi_cmd
}

run_cmd() {
	selected="$(confirm_exit)"
	if [[ "$selected" == "$yes" ]]; then
		case $1 in
			--shutdown) systemctl poweroff ;;
			--reboot) systemctl reboot ;;
			--hibernate) systemctl hibernate ;;
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

# Acción principal
chosen="$(run_rofi)"
case ${chosen} in
    $shutdown) run_cmd --shutdown ;;
    $reboot) run_cmd --reboot ;;
    $hibernate) run_cmd --hibernate ;;
    $lock)
        if command -v swaylock >/dev/null 2>&1; then
            swaylock-fancy
        elif command -v gtklock >/dev/null 2>&1; then
            gtklock
        fi
        ;;
    $suspend) run_cmd --suspend ;;
    $logout) run_cmd --logout ;;
esac
