#!/usr/bin/env bash

status=$(bluetoothctl show | grep "Powered:" | awk '{print $2}')

if [[ "$status" == "yes" ]]; then
  icon=""
  tooltip="Bluetooth activado"
else
  icon=""
  tooltip="Bluetooth desactivado"
fi

echo "{\"text\": \"$icon\", \"tooltip\": \"$tooltip\"}"
