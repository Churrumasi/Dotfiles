#!/bin/bash

PROFILE=$(cat /sys/firmware/acpi/platform_profile)

case "$PROFILE" in
  low-power)
    ICON="battery-caution"
    TEXT="Silencioso"
    COLOR="#4FC3F7"
    ;;
  balanced)
    ICON="battery-good"
    TEXT="Balanceado"
    COLOR="#81C784"
    ;;
  balanced-performance)
    ICON="battery"
    TEXT="Balanceado + Rendimiento"
    COLOR="#FFD54F"
    ;;
  performance)
    ICON="battery-full"
    TEXT="Máximo Rendimiento"
    COLOR="#E57373"
    ;;
  custom)
    ICON="preferences-system"
    TEXT="Modo Personalizado"
    COLOR="#BA68C8"
    ;;
  *)
    ICON="dialog-question"
    TEXT="Perfil desconocido"
    COLOR="#B0BEC5"
    ;;
esac

notify-send \
  -u low \
  -i "$ICON" \
  "Lenovo LOQ" \
  "<span color='$COLOR'><b>$TEXT</b></span>"
