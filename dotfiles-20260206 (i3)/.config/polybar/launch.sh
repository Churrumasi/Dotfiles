#!/bin/bash

# Mata instancias previas
killall -q polybar

# Espera a que mueran
while pgrep -x polybar >/dev/null; do sleep 0.5; done

# Lanza la barra
polybar main &
