#!/usr/bin/env bash

# Verificar si existe un adaptador Bluetooth
if ! bluetoothctl list | grep -q .; then
  exit 1
fi

powered=$(bluetoothctl show | grep "Powered:" | awk '{print $2}')

if [[ "$powered" == "yes" ]]; then
  icon=""
  tooltip="Bluetooth activado. Click para apagar."
else
  icon=""
  tooltip="Bluetooth desactivado. Click para encender."
fi

echo "{\"text\": \"$icon\", \"tooltip\": \"$tooltip\"}"
