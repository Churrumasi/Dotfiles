#!/bin/bash
# backup-debian.sh - Script interactivo para respaldar dotfiles y configuración en Debian
# Autor: Churrumasi
# Adaptado para Debian / Ubuntu / derivadas
# Última actualización: 2026-01

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
  1) ENTORNO="Sway (Debian)" ;;
  2) ENTORNO="Hyprland (Debian)" ;;
  3) ENTORNO="LXDE (Debian)" ;;
  *) echo "❌ Opción inválida. Saliendo..."; exit 1 ;;
esac

# -------------------------------
# 📅 Fecha y nombre del backup
# -------------------------------
FECHA=$(date +%Y%m%d)
BACKUP_DIR="dotfiles-$FECHA ($ENTORNO)"
CONFIG_BACKUP="$BACKUP_DIR/.config"

# -------------------------------
# Listas de configuración por entorno
# -------------------------------
SWAY_ITEMS=(
  waybar wal sway rofi dunst alacritty gtk-2.0 gtk-3.0
  htop fastfetch Thunar xfce4 temas scripts
  user-dirs.locale user-dirs.dirs mimeapps.list
)

HYPRLAND_ITEMS=(
  hypr waybar wal rofi dunst kitty gtk-3.0
  htop fastfetch Thunar xfce4 temas scripts
  user-dirs.locale user-dirs.dirs mimeapps.list
)

LXDE_ITEMS=(
  lxsession openbox pcmanfm wal rofi dunst gtk-2.0 gtk-3.0
  htop fastfetch Thunar xfce4 temas scripts
  user-dirs.locale user-dirs.dirs mimeapps.list
)

if [[ "$ENTORNO" == "Sway (Debian)" ]]; then
  ITEMS=("${SWAY_ITEMS[@]}")
elif [[ "$ENTORNO" == "Hyprland (Debian)" ]]; then
  ITEMS=("${HYPRLAND_ITEMS[@]}")
else
  ITEMS=("${LXDE_ITEMS[@]}")
fi

# -------------------------------
# 📦 Crear carpetas
# -------------------------------
echo "📦 Creando backup en '$BACKUP_DIR'..."
mkdir -p "$CONFIG_BACKUP"

# -------------------------------
# 📦 Guardar lista de paquetes (Debian)
# -------------------------------
echo "📦 Guardando lista de paquetes instalados..."

if command -v apt-mark &>/dev/null; then
  apt-mark showmanual > "$BACKUP_DIR/pkglist-apt-manual.txt"
fi

dpkg --get-selections > "$BACKUP_DIR/pkglist-dpkg.txt"

# -------------------------------
# 🗂️ Respaldar ~/.config
# -------------------------------
echo "🗂️ Respaldando ~/.config..."
for item in "${ITEMS[@]}"; do
  if [[ -f "$HOME/.config/$item" ]]; then
    cp "$HOME/.config/$item" "$CONFIG_BACKUP/"
    echo "✔️ Archivo $item"
  elif [[ -d "$HOME/.config/$item" ]]; then
    cp -r "$HOME/.config/$item" "$CONFIG_BACKUP/"
    echo "✔️ Carpeta $item"
  fi
done

# -------------------------------
# 📄 Dotfiles personales
# -------------------------------
echo "📄 Copiando dotfiles..."
for file in .bashrc .bash_profile .profile .zshrc .p10k.zsh .xinitrc; do
  if [[ -f "$HOME/$file" ]]; then
    cp "$HOME/$file" "$BACKUP_DIR/"
    echo "✔️ $file"
  fi
done

# -------------------------------
# 🖼️ Fondos de pantalla
# -------------------------------
echo "🖼️ Respaldando fondos..."
for dir in "$HOME/fondo" "$HOME/Pictures" "$HOME/Imágenes"; do
  if [[ -d "$dir" ]]; then
    cp -r "$dir" "$BACKUP_DIR/"
    echo "✔️ $dir"
  fi
done

# -------------------------------
# ⚙️ Servicios habilitados
# -------------------------------
echo "⚙️ Guardando servicios habilitados..."
systemctl list-unit-files --state=enabled --no-pager --no-legend \
  | awk '{print $1}' > "$BACKUP_DIR/enabled-services.txt"

# -------------------------------
# ✅ Resumen
# -------------------------------
echo
echo "✅ Backup completado:"
echo "📁 $BACKUP_DIR/"
echo " ├─ .config/"
echo " ├─ pkglist-apt-manual.txt"
echo " ├─ pkglist-dpkg.txt"
echo " ├─ dotfiles personales"
echo " └─ enabled-services.txt"
