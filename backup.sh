#!/bin/bash
# backup.sh - Script interactivo para respaldar dotfiles y configuración en Arch Linux
# Autor: Churrumasi
# Última actualización: 2024-06
#
# Este script permite crear un respaldo completo de la configuración de usuario, dotfiles,
# paquetes instalados y servicios habilitados, adaptado al entorno de escritorio seleccionado.
# El backup se guarda en una carpeta con la fecha y el entorno, facilitando su restauración posterior.
#
# Requisitos:
#   - Arch Linux o derivado
#   - Permisos de lectura sobre los archivos y carpetas a respaldar
#
# El script realiza las siguientes acciones:
#   1. Solicita el entorno de escritorio (Sway, Hyprland, LXDE)
#   2. Define la lista de archivos/carpetas a respaldar según el entorno
#   3. Crea la carpeta de backup con fecha y entorno
#   4. Guarda la lista de paquetes instalados (pacman y AUR)
#   5. Copia la configuración de ~/.config y archivos sueltos
#   6. Copia dotfiles personales (.zshrc, .bashrc, etc)
#   7. Copia la carpeta de fondos si existe
#   8. Guarda la lista de servicios habilitados
#   9. Muestra resumen de los archivos respaldados
#
set -euo pipefail

# -------------------------------
# 🧠 Selección de entorno de escritorio
# -------------------------------
echo "Selecciona tu entorno de escritorio:"
echo "1) Sway"
echo "2) Hyprland"
echo "3) LXDE"
read -rp "Opción (1, 2 o 3): " OPCION

case "$OPCION" in
  1) ENTORNO="Sway" ;;
  2) ENTORNO="Hyprland" ;;
  3) ENTORNO="LXDE" ;;
  *) echo "❌ Opción inválida. Saliendo..."; exit 1 ;;
esac

# -------------------------------
# 📅 Fecha y nombre de carpeta de backup
# -------------------------------
FECHA=$(date +%Y%m%d)
BACKUP_DIR="dotfiles-$FECHA ($ENTORNO)"
CONFIG_BACKUP="$BACKUP_DIR/.config"

# -------------------------------
# Listas de archivos/carpetas a respaldar según entorno
# -------------------------------
SWAY_ITEMS=(
  xfce4 waybar wal Thunar temas sway scripts rofi htop gtk-2.0 fastfetch dunst alacritty
  user-dirs.locale user-dirs.dirs QtProject.conf pavucontrol.ini mimeapps.list kdeglobals
)

HYPRLAND_ITEMS=(
  xfce4 waybar wal Thunar temas scripts rofi Mousepad hypr htop gtk-3.0 fastfetch dunst kitty
  user-dirs.locale user-dirs.dirs QtProject.conf pavucontrol.ini mimeapps.list
)

LXDE_ITEMS=(
  xfce4 wal Thunar temas scripts rofi htop gtk-2.0 gtk-3.0 fastfetch dunst lxsession openbox pcmanfm
  user-dirs.locale user-dirs.dirs QtProject.conf pavucontrol.ini mimeapps.list
)

# Seleccionar lista según entorno
if [[ "$ENTORNO" == "Sway" ]]; then
  ITEMS=("${SWAY_ITEMS[@]}")
elif [[ "$ENTORNO" == "Hyprland" ]]; then
  ITEMS=("${HYPRLAND_ITEMS[@]}")
else
  ITEMS=("${LXDE_ITEMS[@]}")
fi

# -------------------------------
# 📦 Creación de carpeta de backup
# -------------------------------
echo "📦 Creando backup en '$BACKUP_DIR'..."
mkdir -p "$CONFIG_BACKUP"

# -------------------------------
# 📦 Guardar lista de paquetes instalados
# -------------------------------
echo "📦 Guardando lista de paquetes instalados..."
pacman -Qqen > "$BACKUP_DIR/pkglist-pacman.txt"
pacman -Qqem > "$BACKUP_DIR/pkglist-aur.txt"

# -------------------------------
# 🗂️ Respaldar configuración de ~/.config
# -------------------------------
echo "🗂️ Respaldando configuración de ~/.config..."
for item in "${ITEMS[@]}"; do
  if [[ -f "$HOME/.config/$item" ]]; then
    cp "$HOME/.config/$item" "$CONFIG_BACKUP/"
    echo "✔️ Copiado archivo $item"
  elif [[ -d "$HOME/.config/$item" ]]; then
    cp -r "$HOME/.config/$item" "$CONFIG_BACKUP/"
    echo "✔️ Copiada carpeta $item"
  fi
done

# -------------------------------
# Archivos sueltos fuera de .config
# -------------------------------
echo "🔄 Copiando archivos sueltos de configuración..."
for file in user-dirs.locale user-dirs.dirs QtProject.conf pavucontrol.ini mimeapps.list kdeglobals; do
  if [[ " ${ITEMS[@]} " =~ " $file " ]] && [[ -f "$HOME/.config/$file" ]]; then
    cp "$HOME/.config/$file" "$CONFIG_BACKUP/"
    echo "✔️ Copiado archivo $file"
  fi
done

# -------------------------------
# 📄 Copiar otros dotfiles personales
# -------------------------------
echo "📄 Copiando otros dotfiles..."
for file in ".zshrc" ".bashrc" ".xinitrc" ".bash_profile" ".p10k.zsh"; do
  if [[ -f ~/$file ]]; then
    cp ~/$file "$BACKUP_DIR/"
    echo "✔️ Copiado $file"
  else
    echo "⚠️ $file no encontrado"
  fi
done

# -------------------------------
# 🖼️ Respaldar fondos de pantalla
# -------------------------------
echo "🖼️ Respaldando fondos (si existen)..."
if [[ -d ~/fondo ]]; then
    cp -r ~/fondo "$BACKUP_DIR/"
fi

# -------------------------------
# ⚙️ Guardar servicios habilitados
# -------------------------------
echo "⚙️ Guardando servicios habilitados..."
systemctl list-unit-files --state=enabled --no-pager --no-legend | awk '{print $1}' > "$BACKUP_DIR/enabled-services.txt"

# -------------------------------
# ✅ Resumen de backup realizado
# -------------------------------
echo -e "\n✅ Backup completo guardado en '$BACKUP_DIR':"
echo "  - $BACKUP_DIR/pkglist-pacman.txt"
echo "  - $BACKUP_DIR/pkglist-aur.txt"
echo "  - $BACKUP_DIR/.config/"
echo "  - $BACKUP_DIR/.zshrc (etc)"
echo "  - $BACKUP_DIR/enabled-services.txt"
