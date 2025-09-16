#!/bin/bash

# Script para borrar carpetas vacías en una ruta específica

# Pedir ruta
read -rp "Introduce la ruta donde quieres buscar carpetas vacías: " ruta

# Verificar si existe
if [[ ! -d "$ruta" ]]; then
    echo "❌ La ruta no existe."
    exit 1
fi

# Confirmación
echo "⚠️ Se eliminarán TODAS las carpetas vacías en $ruta (incluyendo subcarpetas)."
read -rp "¿Seguro que quieres continuar? (s/n): " confirmacion

if [[ "$confirmacion" != "s" ]]; then
    echo "Operación cancelada."
    exit 0
fi

# Buscar y borrar carpetas vacías
find "$ruta" -type d -empty -delete -print

echo "✅ Proceso completado."
