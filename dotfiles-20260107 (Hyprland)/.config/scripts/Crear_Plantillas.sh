#!/bin/bash

# Carpeta de plantillas
PLANTILLAS="$HOME/.config/Plantillas"

# Crear carpeta si no existe
mkdir -p "$PLANTILLAS"

# Crear plantilla: Documento de texto
cat > "$PLANTILLAS/Documento de texto.txt" <<EOF
Este es un documento de texto.
EOF

# Crear plantilla: Markdown
cat > "$PLANTILLAS/Markdown.md" <<EOF
# Título

Escribe aquí tu contenido en formato Markdown.
EOF

# Crear plantilla: HTML
cat > "$PLANTILLAS/HTML.html" <<EOF
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Documento</title>
</head>
<body>
  <h1>Hola Mundo</h1>
</body>
</html>
EOF

# Crear plantilla: Script Bash
cat > "$PLANTILLAS/Script Bash.sh" <<EOF
#!/bin/bash
# Script de ejemplo

echo "Hola mundo"
EOF
chmod +x "$PLANTILLAS/Script Bash.sh"

# Crear plantilla: Python
cat > "$PLANTILLAS/Python.py" <<EOF
#!/usr/bin/env python3

def main():
    print("Hola desde Python!")

if __name__ == "__main__":
    main()
EOF
chmod +x "$PLANTILLAS/Python.py"

# Crear plantilla: Archivo vacío
touch "$PLANTILLAS/Archivo vacío"

# Crear plantilla: JSON
cat > "$PLANTILLAS/Ejemplo.json" <<EOF
{
  "nombre": "Plantilla",
  "activo": true
}
EOF

# Crear plantilla: YAML
cat > "$PLANTILLAS/Ejemplo.yaml" <<EOF
nombre: Plantilla
activo: true
EOF

# Crear plantilla: CSS
cat > "$PLANTILLAS/Estilo.css" <<EOF
body {
  font-family: sans-serif;
  background-color: #f0f0f0;
}
EOF

# Crear plantilla: JavaScript
cat > "$PLANTILLAS/Script.js" <<EOF
document.addEventListener('DOMContentLoaded', () => {
  console.log('Hola desde JavaScript');
});
EOF

echo "✅ Plantillas creadas en: $PLANTILLAS"
