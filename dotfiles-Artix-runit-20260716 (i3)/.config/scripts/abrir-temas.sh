#!/usr/bin/env bash

BUSQUEDA="$1"
TEMAS_DIR="$HOME/.config/temas"

json="["

for dir in "$TEMAS_DIR"/*; do
    [ -d "$dir" ] || continue

    nombre=$(basename "$dir")

    if [[ "$nombre" =~ $BUSQUEDA ]]; then
        imagen="$dir/fondo.png"
        json+="{\"nombre\":\"$nombre\",\"imagen\":\"$imagen\"},"
    fi
done

json="${json%,}]"

eww update temas="$json"
