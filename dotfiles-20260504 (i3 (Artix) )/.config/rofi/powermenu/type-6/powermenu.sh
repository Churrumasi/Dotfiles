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

rofi_cmd() {
	rofi -dmenu \
		-p " $USER@$host" \
		-mesg " Tiempo activo: $uptime" \
		-theme "${dir}/${theme}.rasi"
}

confirm_cmd() {
	rofi -theme-str 'window {location: center; anchor: center; fullscreen: false; width: 350px;}' \
		-theme-str 'mainbox {orientation: vertical; children: [ "message", "listview" ];}' \
		-theme-str 'listview {columns: 2; lines: 1;}' \
		-theme-str 'element-text {horizontal-align: 0.5;}' \
		-theme-str 'textbox {horizontal-align: 0.5;}' \
		-dmenu \
		-p 'Confirmation' \
		-mesg '¿Estás seguro?' \
		-theme "${dir}/${theme}.rasi"
}

confirm_exit() {
	printf '%s\n%s\n' "$yes" "$no" | confirm_cmd
}

run_rofi() {
	printf '%s\n%s\n%s\n%s\n%s\n%s\n' "$lock" "$suspend" "$logout" "$hibernate" "$reboot" "$shutdown" | rofi_cmd
}

run_cmd() {
	selected="$(confirm_exit)"
	if [[ "$selected" == "$yes" ]]; then
		case $1 in
			--shutdown) loginctl poweroff ;;
			--reboot) loginctl reboot ;;
			--hibernate) loginctl hibernate ;;
			--suspend)
    				i3lock-fancy
    				sleep 1
    				loginctl suspend
    				;;
			--logout)
				i3-msg exit
				;;
		esac
	else
		exit 0
	fi
}

chosen="$(run_rofi)"
case "$chosen" in
	"$shutdown") run_cmd --shutdown ;;
	"$reboot") run_cmd --reboot ;;
	"$hibernate") run_cmd --hibernate ;;
	"$lock")
		if command -v i3lock-fancy >/dev/null 2>&1; then
			i3lock-fancy
		elif command -v gtklock >/dev/null 2>&1; then
			gtklock
		fi
		;;
	"$suspend") run_cmd --suspend ;;
	"$logout") run_cmd --logout ;;
esac