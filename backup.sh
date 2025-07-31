#!/bin/bash

set -euo pipefail

# 🧠 Preguntar al usuario por el entorno de escritorio
echo "Selecciona tu entorno de escritorio:"
echo "1) Sway"
echo "2) Hyprland"
read -rp "Opción (1 o 2): " OPCION

case "$OPCION" in
  1) ENTORNO="Sway" ;;
  2) ENTORNO="Hyprland" ;;
  *) echo "❌ Opción inválida. Saliendo..."; exit 1 ;;
esac

# 📅 Fecha y nombre de carpeta con entorno
FECHA=$(date +%Y%m%d)
BACKUP_DIR="dotfiles-$FECHA ($ENTORNO)"
CONFIG_BACKUP="$BACKUP_DIR/.config"

# Listas de carpetas/archivos a respaldar según entorno
SWAY_ITEMS=(
  xfce4 waybar wal Thunar temas sway scripts rofi oomox-gtk-theme htop gtk-2.0 fastfetch dunst alacritty 
  user-dirs.locale user-dirs.dirs QtProject.conf pavucontrol.ini mimeapps.list kdeglobals
)
HYPRLAND_ITEMS=(
  xfce4 waybar wal Thunar temas scripts rofi oomox-gtk-theme Mousepad hypr htop gtk-3.0 fastfetch dunst alacritty 
  user-dirs.locale user-dirs.dirs QtProject.conf pavucontrol.ini mimeapps.list
)

if [[ "$ENTORNO" == "Sway" ]]; then
  ITEMS=("${SWAY_ITEMS[@]}")
else
  ITEMS=("${HYPRLAND_ITEMS[@]}")
fi

echo "📦 Creando backup en '$BACKUP_DIR'..."
mkdir -p "$CONFIG_BACKUP"

echo "📦 Guardando lista de paquetes instalados..."
pacman -Qqen > "$BACKUP_DIR/pkglist-pacman.txt"
pacman -Qqem > "$BACKUP_DIR/pkglist-aur.txt"

echo "🗂️ Respaldando configuración de ~/.config..."
for item in "${ITEMS[@]}"; do
  # Si es archivo especial (no carpeta), copiar directo
  if [[ -f "$HOME/.config/$item" ]]; then
    cp "$HOME/.config/$item" "$CONFIG_BACKUP/"
    echo "✔️ Copiado archivo $item"
  elif [[ -d "$HOME/.config/$item" ]]; then
    cp -r "$HOME/.config/$item" "$CONFIG_BACKUP/"
    echo "✔️ Copiada carpeta $item"
  fi
done

# Archivos sueltos fuera de .config
for file in user-dirs.locale user-dirs.dirs QtProject.conf pavucontrol.ini mimeapps.list kdeglobals; do
  # Solo respaldar si está en la lista de ITEMS
  if [[ " ${ITEMS[@]} " =~ " $file " ]] && [[ -f "$HOME/.config/$file" ]]; then
    cp "$HOME/.config/$file" "$CONFIG_BACKUP/"
    echo "✔️ Copiado archivo $file"
  fi
done

echo "📄 Copiando otros dotfiles..."
for file in ".zshrc" ".bashrc" ".xinitrc" ".bash_profile" ".p10k.zsh"; do
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


echo "⚙️ Guardando servicios habilitados..."
systemctl list-unit-files --state=enabled --no-pager --no-legend | awk '{print $1}' > "$BACKUP_DIR/enabled-services.txt"

echo -e "\n✅ Backup completo guardado en '$BACKUP_DIR':"
echo "  - $BACKUP_DIR/pkglist-pacman.txt"
echo "  - $BACKUP_DIR/pkglist-aur.txt"
echo "  - $BACKUP_DIR/.config/"
echo "  - $BACKUP_DIR/.zshrc (etc)"
echo "  - $BACKUP_DIR/enabled-services.txt"
