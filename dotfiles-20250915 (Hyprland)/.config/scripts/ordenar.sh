#!/bin/bash

# Carpeta base donde buscar
read -rp "Ruta de la carpeta donde buscar: " BASE_DIR
BASE_DIR="${BASE_DIR:-.}"

# Carpeta de destino
DEST_DIR="resultados"
mkdir -p "$DEST_DIR"

# Pedir nombre (opcional)
read -rp "Parte del nombre a buscar (deja vacío si no aplica): " NOMBRE

# Pedir extensión (opcional, sin el punto)
read -rp "Extensión a buscar (sin el punto, deja vacío si no aplica): " EXT

# Construir comando de búsqueda
FIND_CMD=(find "$BASE_DIR" -type f)

if [[ -n "$NOMBRE" ]]; then
    FIND_CMD+=(-iname "*$NOMBRE*")
fi

if [[ -n "$EXT" ]]; then
    FIND_CMD+=(-iname "*.$EXT")
fi

# Buscar archivos
echo "Buscando archivos..."
ARCHIVOS=()
while IFS= read -r archivo; do
    ARCHIVOS+=("$archivo")
done < <("${FIND_CMD[@]}")

if [[ ${#ARCHIVOS[@]} -eq 0 ]]; then
    echo "No se encontraron archivos."
    exit 1
fi

# Mover y renombrar si es necesario
for archivo in "${ARCHIVOS[@]}"; do
    nombre_original=$(basename "$archivo")
    nombre_sin_ext="${nombre_original%.*}"
    extension="${nombre_original##*.}"

    nuevo_nombre="$nombre_original"
    contador=1

    # Mientras exista un archivo con ese nombre, renombrar
    while [[ -e "$DEST_DIR/$nuevo_nombre" ]]; do
        nuevo_nombre="${nombre_sin_ext}_$contador.$extension"
        ((contador++))
    done

    mv "$archivo" "$DEST_DIR/$nuevo_nombre"
done

echo "Se movieron ${#ARCHIVOS[@]} archivos a la carpeta '$DEST_DIR' con renombrado automático si fue necesario."
