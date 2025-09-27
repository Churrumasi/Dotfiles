#!/usr/bin/env bash

STATE_FILE="$HOME/.cache/waybar_net_mode"

# Función para verificar conectividad a internet
check_internet() {
  ping -q -w 1 -c 1 8.8.8.8 > /dev/null 2>&1
}

# Detectar interfaces activas
eth_iface=$(ip link | grep -E 'state UP' | grep -oE 'en[a-z0-9]+' | head -n1)
wifi_iface=$(ip link | grep -E 'state UP' | grep -oE 'wl[a-z0-9]+' | head -n1)

# Si no hay ninguna interfaz activa
if [[ -z "$eth_iface" && -z "$wifi_iface" ]]; then
  echo '{"text": "󰤭", "tooltip": "Sin conexión de red"}'
  exit 0
fi

# Obtener modo actual o inicializar
mode="wifi"
[[ -f "$STATE_FILE" ]] && mode=$(<"$STATE_FILE")

# Alternar si se recibe clic (botón 1)
if [[ "$1" == "toggle" ]]; then
  [[ "$mode" == "wifi" ]] && echo "eth" > "$STATE_FILE" || echo "wifi" > "$STATE_FILE"
  exit 0
fi

# Si solo una interfaz está activa, forzar mostrar esa
[[ -z "$wifi_iface" ]] && mode="eth"
[[ -z "$eth_iface" ]] && mode="wifi"

# Mostrar según modo actual
if [[ "$mode" == "wifi" ]]; then
  if iw dev "$wifi_iface" link | grep -q 'Connected'; then
    ssid=$(iw dev "$wifi_iface" link | grep 'SSID' | cut -d ' ' -f2-)
    signal_dbm=$(iw dev "$wifi_iface" link | grep 'signal' | awk '{print $2}')
    signal_perc=$((2 * ($signal_dbm + 100)))
    [[ $signal_perc -lt 0 ]] && signal_perc=0
    [[ $signal_perc -gt 100 ]] && signal_perc=100

    # Elegir icono
    if [ "$signal_perc" -ge 80 ]; then icon="󰤨"
    elif [ "$signal_perc" -ge 60 ]; then icon="󰤥"
    elif [ "$signal_perc" -ge 40 ]; then icon="󰤢"
    elif [ "$signal_perc" -ge 20 ]; then icon="󰤟"
    else icon="󰤯"; fi

    tooltip="WiFi: $ssid\nSeñal: ${signal_perc}%"
    check_internet || tooltip="$tooltip\nInternet: ❌ Sin conexión"

    echo "{\"text\": \"$icon $ssid\", \"tooltip\": \"$tooltip\"}"
  else
    echo '{"text": "󰤭", "tooltip": "WiFi no conectado"}'
  fi
else
  icon="󰈀"
  tooltip="Conexión por cable ($eth_iface)"
  check_internet || {
    icon="󰈂"
    tooltip="$tooltip\nInternet: ❌ Sin conexión"
  }

  echo "{\"text\": \"$icon $eth_iface\", \"tooltip\": \"$tooltip\"}"
fi
