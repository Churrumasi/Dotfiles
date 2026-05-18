#!/bin/bash
# backup.sh - Script interactivo para respaldar dotfiles y configuración en Artix Linux (runit)
# Autor: Churrumasi
#
# Este script permite crear un respaldo completo de la configuración de usuario, dotfiles,
# paquetes instalados y servicios habilitados, adaptado a Artix Linux con runit.
# El backup se guarda en una carpeta con la fecha y el entorno, facilitando su restauración posterior.

set -euo pipefail

# -------------------------------
# 🧠 Selección de entorno de escritorio
# -------------------------------
echo "Selecciona tu entorno de escritorio:"
echo "1) Sway"
echo "2) Hyprland"
echo "3) LXDE"
echo "4) i3"
read -rp "Opción (1, 2, 3 o 4): " OPCION

case "$OPCION" in
  1) ENTORNO="Sway" ;;
  2) ENTORNO="Hyprland" ;;
  3) ENTORNO="LXDE" ;;
  4) ENTORNO="i3" ;;
  *) echo "❌ Opción inválida. Saliendo..."; exit 1 ;;
esac

# -------------------------------
# 📅 Fecha y nombre de carpeta de backup
# -------------------------------
FECHA=$(date +%Y%m%d)
# Diferenciación para Artix con runit en el nombre de la carpeta
BACKUP_DIR="dotfiles-Artix-runit-$FECHA ($ENTORNO)"
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
  user-dirs.locale user-dirs.dirs QtProject.conf pavucontrol.ini mimeapps.list alacritty
)

I3_ITEMS=(
  alacritty dunst fastfetch fastfetch-femboy-editicon gtk-2.0 gtk-3.0 htop i3 kitty logos
  picom Plantillas polybar rofi scripts temas xfce4 kactivitymanagerdrc khelpcenterrc
  user-dirs.locale user-dirs.dirs QtProject.conf pavucontrol.ini mimeapps.list lxtask.conf
  pmbootstrap_v3.cfg powermanagementprofilesrc wal
)

# Seleccionar lista según entorno
case "$ENTORNO" in
  "Sway") ITEMS=("${SWAY_ITEMS[@]}") ;;
  "Hyprland") ITEMS=("${HYPRLAND_ITEMS[@]}") ;;
  "LXDE") ITEMS=("${LXDE_ITEMS[@]}") ;;
  "i3") ITEMS=("${I3_ITEMS[@]}") ;;
esac

# -------------------------------
# Función para copiar archivos o carpetas
# -------------------------------
copy_item() {
  local src="$1"
  local dst_dir="$2"

  if [[ -e "$src" ]]; then
    cp -a "$src" "$dst_dir/"
    echo "✔️ Copiado $(basename "$src")"
  fi
}

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
  copy_item "$HOME/.config/$item" "$CONFIG_BACKUP"
done

# -------------------------------
# 📄 Copiar otros dotfiles personales
# -------------------------------
echo "📄 Copiando otros dotfiles..."
for file in ".zshrc" ".bashrc" ".bash_profile" ".profile" ".xinitrc" ".xprofile" ".p10k.zsh"; do
  if [[ -f "$HOME/$file" ]]; then
    cp -a "$HOME/$file" "$BACKUP_DIR/"
    echo "✔️ Copiado $file"
  else
    echo "⚠️ $file no encontrado"
  fi
done

# -------------------------------
# 🖼️ Respaldar fondos de pantalla
# -------------------------------
echo "🖼️ Respaldando fondos (si existen)..."
if [[ -d "$HOME/fondo" ]]; then
  cp -a "$HOME/fondo" "$BACKUP_DIR/"
  echo "✔️ Copiada carpeta fondo"
fi

# -------------------------------
# ⚙️ Guardar servicios habilitados en runit
# -------------------------------
echo "⚙️ Guardando servicios habilitados de runit..."

SERVICE_DIRS=(
  "/etc/runit/runsvdir/current"
  "/etc/runit/runsvdir/default"
  "/run/runit/service"
)

{
  for dir in "${SERVICE_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
      find "$dir" -mindepth 1 -maxdepth 1 -type l -printf '%f\n' 2>/dev/null
    fi
  done
} | sort -u > "$BACKUP_DIR/enabled-services.txt"

if [[ ! -s "$BACKUP_DIR/enabled-services.txt" ]]; then
  echo "No se encontraron servicios habilitados en rutas típicas de runit." > "$BACKUP_DIR/enabled-services.txt"
fi
# -------------------------------
# 🛠️ Respaldar servicios personalizados de runit
# -------------------------------
echo "🛠️ Respaldando servicios personalizados de runit..."

CUSTOM_SERVICES_DIR="$BACKUP_DIR/runit-services"
mkdir -p "$CUSTOM_SERVICES_DIR"

for service in /etc/runit/sv/*; do
  SERVICE_NAME=$(basename "$service")

  # Ignorar servicios comunes del sistema
  case "$SERVICE_NAME" in
    agetty-*|dbus|NetworkManager|connmand|sshd|cron|cronie|udevd|syslog-ng|dhcpcd)
      continue
      ;;
  esac

  if [[ -d "$service" ]]; then
    mkdir -p "$CUSTOM_SERVICES_DIR/$SERVICE_NAME"

    # Copiar todo EXCEPTO supervise
    rsync -a --exclude='supervise' "$service/" "$CUSTOM_SERVICES_DIR/$SERVICE_NAME/"

    echo "✔️ Servicio respaldado: $SERVICE_NAME"
  fi
done
# -------------------------------
# ✅ Resumen de backup realizado
# -------------------------------
echo
echo "✅ Backup completo guardado en '$BACKUP_DIR':"
echo "  - $BACKUP_DIR/pkglist-pacman.txt"
echo "  - $BACKUP_DIR/pkglist-aur.txt"
echo "  - $BACKUP_DIR/.config/"
echo "  - $BACKUP_DIR/.zshrc / .bashrc / etc"
echo "  - $BACKUP_DIR/enabled-services.txt"