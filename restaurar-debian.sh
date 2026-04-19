#!/bin/bash
# restaurar-debian.sh - Restaurar dotfiles y entorno en Debian
# Autor: Churrumasi
# Adaptación completa Arch → Debian
# Fecha: 2026-01

set -euo pipefail

confirmar() {
    local pregunta="${1:-¿Continuar?}"
    read -rp "$pregunta (s/n): " RESP
    [[ "$RESP" =~ ^[sS]$ ]]
}

# -------------------------------
# 📁 Selección de backup
# -------------------------------
echo "📁 Buscando backups disponibles..."
mapfile -t BACKUPS < <(ls -d dotfiles-* 2>/dev/null | sort -r)

[[ ${#BACKUPS[@]} -eq 0 ]] && {
    echo "❌ No se encontraron backups dotfiles-*"
    exit 1
}

select BACKUP in "${BACKUPS[@]}"; do
    [[ -n "$BACKUP" ]] && break
done

echo "✔️ Backup seleccionado: $BACKUP"

# -------------------------------
# 📦 Restaurar paquetes
# -------------------------------
if confirmar "¿Instalar paquetes del backup (apt)?"; then
    sudo apt update

    if [[ -f "$BACKUP/pkglist-apt-manual.txt" ]]; then
        sudo xargs -a "$BACKUP/pkglist-apt-manual.txt" apt install -y
    else
        echo "⚠️ pkglist-apt-manual.txt no encontrado"
    fi
fi

# -------------------------------
# 🌀 Zsh + Oh My Zsh + Powerlevel10k
# -------------------------------
if confirmar "¿Instalar Zsh + Oh My Zsh + Powerlevel10k?"; then
    sudo apt install -y zsh git curl fonts-firacode

    chsh -s "$(command -v zsh)"

    if [[ ! -d ~/.oh-my-zsh ]]; then
        RUNZSH=no KEEP_ZSHRC=yes sh -c \
          "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi

    if [[ ! -d ~/.oh-my-zsh/custom/themes/powerlevel10k ]]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
          ~/.oh-my-zsh/custom/themes/powerlevel10k
    fi

    sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
fi

# -------------------------------
# 🎨 Tema de iconos Tela Circle
# -------------------------------
if confirmar "¿Instalar iconos Tela Circle?"; then
    sudo apt install -y meson ninja-build sassc libgtk-3-dev

    git clone https://github.com/vinceliuice/Tela-circle-icon-theme.git
    cd Tela-circle-icon-theme
    ./install.sh -a
    cd ..
    rm -rf Tela-circle-icon-theme
fi

# -------------------------------
# 🎨 Temas Rofi
# -------------------------------
if confirmar "¿Instalar temas Rofi?"; then
    sudo apt install -y rofi

    git clone --depth=1 https://github.com/adi1090x/rofi.git
    cd rofi
    chmod +x setup.sh
    ./setup.sh
    cd ..
    rm -rf rofi
fi

# -------------------------------
# 🗂️ Restaurar ~/.config
# -------------------------------
if confirmar "¿Restaurar ~/.config?"; then
    mkdir -p ~/.config
    cp -rT "$BACKUP/.config" ~/.config
fi

# -------------------------------
# 🏠 Restaurar dotfiles
# -------------------------------
if confirmar "¿Restaurar dotfiles personales?"; then
    for f in .bashrc .bash_profile .profile .zshrc .p10k.zsh .xinitrc; do
        [[ -f "$BACKUP/$f" ]] && cp "$BACKUP/$f" ~/
    done
fi

# -------------------------------
# ⚙️ Activar servicios
# -------------------------------
if confirmar "¿Activar servicios guardados?"; then
    if [[ -f "$BACKUP/enabled-services.txt" ]]; then
        while read -r svc; do
            sudo systemctl enable "$svc" || true
        done < "$BACKUP/enabled-services.txt"
    fi
fi

# -------------------------------
# 🔧 Configurar Git
# -------------------------------
if confirmar "¿Configurar Git?"; then
    git config --global user.name "Churrumasi"
    git config --global user.email "j63954923@gmail.com"
fi

# -------------------------------
# 🎨 Oomox GTK (Debian)
# -------------------------------
if confirmar "¿Generar temas GTK con Oomox?"; then
    sudo apt install -y \
      bc sassc libglib2.0-bin libgdk-pixbuf2.0-dev \
      librsvg2-bin python3 python3-gi

    git clone https://github.com/themix-project/oomox.git
    cd oomox

    for TEMA in "$HOME/.config/temas"/*; do
        FONDO="$TEMA/fondo.png"
        [[ -f "$FONDO" ]] || continue

        wal -i "$FONDO"
        ./plugins/theme_oomox/change_color.sh \
          -o "my-wal-theme-$(basename "$TEMA" | tr 'A-Z' 'a-z')" \
          ~/.cache/wal/colors-oomox
    done

    cd ..
    rm -rf oomox
fi
if confirmar "¿Deseas instalar el tema SDDM Astronaut?"; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/keyitdev/sddm-astronaut-theme/master/setup.sh)"
else
    echo "Instalación del tema SDDM Astronaut omitida."
fi

# -------------------------------
# 🔄 Reinicio
# -------------------------------
if confirmar "¿Reiniciar ahora?"; then
    reboot
else
    echo "✔️ Restauración finalizada"
fi
