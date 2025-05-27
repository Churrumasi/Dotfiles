#!/bin/bash

set -euo pipefail

FECHA=$(date +%Y%m%d)
BACKUP_DIR="dotfiles-$FECHA"
CONFIG_BACKUP="$BACKUP_DIR/.config"

echo "📦 Creando backup en '$BACKUP_DIR'..."
mkdir -p "$CONFIG_BACKUP"

echo "📦 Guardando lista de paquetes instalados..."
pacman -Qqen > "$BACKUP_DIR/pkglist-pacman.txt"
pacman -Qqem > "$BACKUP_DIR/pkglist-aur.txt"

echo "🗂️ Respaldando configuración de ~/.config..."
rsync -av --exclude='discord' \
          --exclude='Code' \
          --exclude='electron-flags.conf' \
          ~/.config/ "$CONFIG_BACKUP/"

echo "📄 Copiando otros dotfiles..."
for file in ".zshrc" ".bashrc" ".xinitrc" ".bash_profile"; do
  if [[ -f ~/$file ]]; then
    cp ~/$file "$BACKUP_DIR/"
    echo "✔️ Copiado $file"
  else
    echo "⚠️ $file no encontrado"
  fi
done

echo "🖼️ Respaldando fondos (si existen)..."
if [[ -d ~/fondo ]]; then
    cp -r ~/fondo "$BACKUP_DIR/"
fi

echo "🔤 Respaldando fuentes locales (si existen)..."
if [[ -d ~/.local/share/fonts ]]; then
    mkdir -p "$BACKUP_DIR/fonts"
    cp -r ~/.local/share/fonts/* "$BACKUP_DIR/fonts/"
fi

echo "⚙️ Guardando servicios habilitados..."
systemctl list-unit-files --state=enabled --no-pager --no-legend | awk '{print $1}' > "$BACKUP_DIR/enabled-services.txt"

echo -e "\n✅ Backup completo guardado en '$BACKUP_DIR':"
echo "  - $BACKUP_DIR/pkglist-pacman.txt"
echo "  - $BACKUP_DIR/pkglist-aur.txt"
echo "  - $BACKUP_DIR/.config/"
echo "  - $BACKUP_DIR/.zshrc (etc)"
echo "  - $BACKUP_DIR/enabled-services.txt"
