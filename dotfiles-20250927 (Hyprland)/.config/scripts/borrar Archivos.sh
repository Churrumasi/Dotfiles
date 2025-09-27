#!/bin/bash

# Script para borrar archivos de una extensión en una ruta específica

# Pedir ruta
read -rp "Introduce la ruta donde quieres buscar archivos: " ruta

# Verificar si existe
if [[ ! -d "$ruta" ]]; then
    echo "❌ La ruta no existe."
    exit 1
fi

# Pedir extensión
read -rp "Introduce la extensión de archivo a eliminar (ejemplo: png): " extension

# Confirmación
echo "⚠️ Se eliminarán TODOS los archivos *.$extension en $ruta (incluyendo subcarpetas)."
read -rp "¿Seguro que quieres continuar? (s/n): " confirmacion

if [[ "$confirmacion" != "s" ]]; then
    echo "Operación cancelada."
    exit 0
fi

# Buscar y borrar
find "$ruta" -type f -iname "*.$extension" -exec rm -v {} +

echo "✅ Proceso completado."
