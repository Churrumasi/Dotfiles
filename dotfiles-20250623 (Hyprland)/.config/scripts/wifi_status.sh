#!/usr/bin/env bash

# Función para verificar conectividad a internet (retorna 0 si hay conexión)
check_internet() {
  ping -q -w 1 -c 1 8.8.8.8 >/dev/null 2>&1
}

# Detectar interfaz activa
active_iface=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $5}' | head -n1)

# Sin conexión activa
if [[ -z "$active_iface" ]]; then
  echo '{"text": "󰤭", "tooltip": "Sin conexión a red"}'
  exit 0
fi

# Verificar si es WiFi
if iw dev "$active_iface" link 2>/dev/null | grep -q 'Connected'; then
  ssid=$(iw dev "$active_iface" link | grep 'SSID' | cut -d ' ' -f2-)
  signal_dbm=$(iw dev "$active_iface" link | grep 'signal' | awk '{print $2}')
  signal_perc=$((2 * ($signal_dbm + 100)))
  [[ $signal_perc -lt 0 ]] && signal_perc=0
  [[ $signal_perc -gt 100 ]] && signal_perc=100

  # Elegir icono según señal
  if [ "$signal_perc" -ge 80 ]; then
    icon="󰤨"
  elif [ "$signal_perc" -ge 60 ]; then
    icon="󰤥"
  elif [ "$signal_perc" -ge 40 ]; then
    icon="󰤢"
  elif [ "$signal_perc" -ge 20 ]; then
    icon="󰤟"
  else
    icon="󰤯"
  fi

  # Verificar conectividad a internet
  if check_internet; then
    tooltip="Red: $ssid\nSeñal: ${signal_perc}%\nInternet: ✅ Disponible"
  else
    tooltip="Red: $ssid\nSeñal: ${signal_perc}%\nInternet: ❌ Sin conexión"
    icon="󰤫" # Ícono con barra cortada
  fi

  echo "{\"text\": \"$icon $ssid\", \"tooltip\": \"$tooltip\"}"

else
  # Es conexión por cable
  icon="󰈀"
  if check_internet; then
    tooltip="Conectado por cable a $active_iface\nInternet: ✅ Disponible"
  else
    tooltip="Conectado por cable a $active_iface\nInternet: ❌ Sin conexión"
    icon="󰈂" # Cable sin internet
  fi

  echo "{\"text\": \"$icon $active_iface\", \"tooltip\": \"$tooltip\"}"
fi

