#!/bin/bash
#
set -euo pipefail

# Función para confirmar acciones
confirmar() {
    local pregunta="${1:-¿Continuar?}"
    read -rp "$pregunta (s/n): " RESP
    [[ "$RESP" =~ ^[sS]$ ]]
}


# -------------------------------
# ➕ Agregar Chaotic AUR (versión oficial)
# -------------------------------
if confirmar "¿Quieres agregar el repositorio Chaotic AUR?"; then
    echo "Importando clave de Chaotic AUR..."
    sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    sudo pacman-key --lsign-key 3056513887B78AEB

    echo "Instalando chaotic-keyring y chaotic-mirrorlist..."
    sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
    sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

    echo "Añadiendo chaotic-aur al pacman.conf..."
    if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
        echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf
    else
        echo "chaotic-aur ya está en /etc/pacman.conf, omitiendo."
    fi

    echo "Sincronizando e iniciando actualización..."
    sudo pacman -Syu
fi
# -------------------------------
# 🛠 Instalar yay
# -------------------------------
if confirmar "¿Quieres verificar/instalar yay?"; then
    if ! command -v yay &> /dev/null; then
        echo "Instalando yay..."
        sudo pacman -S --needed --noconfirm git base-devel
        git clone https://aur.archlinux.org/yay-bin.git
        cd yay-bin
        makepkg -si --noconfirm
        cd ..
        rm -rf yay-bin
    else
        echo "yay ya está instalado."
    fi
fi
# -------------------------------
# 🎨 GRUB 
# -------------------------------
if confirmar "¿Deseas instalar los temas de GRUB?"; then
    git clone https://github.com/ChrisTitusTech/Top-5-Bootloader-Themes
    cd Top-5-Bootloader-Themes
    sudo ./install.sh
    cd ..
    rm -rf Top-5-Bootloader-Themes
fi

# -------------------------------
# 🌀 Zsh y Oh My Zsh
# -------------------------------
if confirmar "¿Quieres instalar Zsh y Oh My Zsh?"; then
    if ! command -v zsh &> /dev/null; then
        sudo pacman -S --needed --noconfirm zsh
    fi

    ZSH_PATH="$(command -v zsh)"
    if ! grep -q "$ZSH_PATH" /etc/shells; then
        echo "$ZSH_PATH" | sudo tee -a /etc/shells
    fi

    if [[ "$SHELL" != "$ZSH_PATH" ]]; then
        chsh -s "$ZSH_PATH"
    fi

    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi

    yay -S --noconfirm zsh-theme-powerlevel10k-git
    if ! grep -q "powerlevel10k.zsh-theme" ~/.zshrc; then
        echo 'source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme' >> ~/.zshrc
    fi

    if [[ -f ~/.cache/wal/colors-tty.sh ]]; then
        chmod +x ~/.cache/wal/colors-tty.sh
        if ! grep -q "colors-tty.sh" ~/.zshrc; then
            echo "source ~/.cache/wal/colors-tty.sh" >> ~/.zshrc
        fi
    fi
fi

# -------------------------------
# 🎨 Iconos Tela Circle
# -------------------------------
if confirmar "¿Deseas instalar el tema de iconos Tela Circle?"; then
    echo "Instalando tema de iconos Tela Circle..."
    yay -S --noconfirm tela-circle-icon-theme

else
    echo "Tema de iconos omitido."
fi

# -------------------------------
# 📁 Selección de backup
# -------------------------------
if confirmar "¿Deseas seleccionar un backup para restaurar?"; then
    echo "Buscando backups disponibles..."
    mapfile -t BACKUPS < <(ls -d dotfiles-* 2>/dev/null | sort -r)

    if [[ ${#BACKUPS[@]} -eq 0 ]]; then
        echo "❌ No se encontró ningún directorio de backup 'dotfiles-YYYYMMDD'."
        exit 1
    fi

    echo "Backups disponibles:"
    select LATEST_BACKUP in "${BACKUPS[@]}"; do
        if [[ -n "$LATEST_BACKUP" ]]; then
            echo "Seleccionaste: $LATEST_BACKUP"
            break
        else
            echo "Selección inválida, intenta de nuevo."
        fi
    done
else
    echo "Restauración cancelada."
    exit 0
fi


# -------------------------------
# 📦 Instalación de paquetes
# -------------------------------
if confirmar "¿Deseas instalar los paquetes del backup?"; then
    if [[ -f "$LATEST_BACKUP/pkglist-pacman.txt" ]]; then
        sudo pacman -S --needed - < "$LATEST_BACKUP/pkglist-pacman.txt"
    else
        echo "No se encontró pkglist-pacman.txt en $LATEST_BACKUP"
    fi

    if [[ -f "$LATEST_BACKUP/pkglist-aur.txt" ]]; then
        yay -S --needed --noconfirm - < "$LATEST_BACKUP/pkglist-aur.txt"
    else
        echo "No se encontró pkglist-aur.txt en $LATEST_BACKUP"
    fi
fi

# -------------------------------
# 🎨 Rofi y configuración
# -------------------------------
if confirmar "¿Deseas instalar los temas de rofi?"; then
    if [[ ! -d rofi ]]; then
        git clone --depth=1 https://github.com/adi1090x/rofi.git
        cd rofi
        chmod +x setup.sh
        ./setup.sh
        cd ..
        rm -rf rofi
    else
        echo "Carpeta 'rofi' ya existe, saltando."
    fi
fi

if confirmar "¿Deseas restaurar la carpeta ~/.config?"; then
    mkdir -p ~/.config
    cp -rT "$LATEST_BACKUP/.config" ~/.config
fi

if confirmar "¿Deseas restaurar los dotfiles personales?"; then
    for file in ".zshrc" ".bashrc" ".xinitrc" ".bash_profile"  ".p10k.zsh"; do
        if [[ -f "$LATEST_BACKUP/$file" ]]; then
            cp "$LATEST_BACKUP/$file" ~/
            echo "Restaurado $file"
        else
            echo "$file no encontrado en $LATEST_BACKUP"
        fi
    done
fi


# -------------------------------
# ⚙️ Servicios y git 
# -------------------------------
if confirmar "¿Deseas activar servicios guardados?"; then
    if [[ -f "$LATEST_BACKUP/enabled-services.txt" ]]; then
        while read -r service; do
            [[ -n "$service" ]] && sudo systemctl enable "$service"
        done < "$LATEST_BACKUP/enabled-services.txt"
    else
        echo "enabled-services.txt no encontrado en $LATEST_BACKUP"
    fi
fi

if confirmar "¿Deseas configurar Git con tus datos?"; then
    git config --global user.name "Churrumasi"
    git config --global user.email "j63954923@gmail.com"
fi



if confirmar "¿Quieres generar temas GTK con Oomox para todos los temas de ~/.config/temas?"; then
    echo "Instalando dependencias para Oomox..."
    sudo pacman -S --needed --noconfirm bash grep sed bc glib2 gdk-pixbuf2 sassc gtk-engine-murrine gtk-engines librsvg

    echo "Clonando Oomox GTK Theme..."
    git clone https://github.com/themix-project/oomox-gtk-theme.git
    cd oomox-gtk-theme

    for TEMA_DIR in "$HOME/.config/temas"/*; do
        [ -d "$TEMA_DIR" ] || continue
        NOMBRE_TEMA=$(basename "$TEMA_DIR")

        FONDO="$TEMA_DIR/fondo.png"
        [ -f "$FONDO" ] || { echo "Sin fondo en $NOMBRE_TEMA, omitiendo..."; continue; }

        echo "Aplicando wal con fondo: $FONDO"
        wal -i "$FONDO"

        THEME_NAME="my-wal-theme-${NOMBRE_TEMA,,}"  # en minúsculas
        echo "Generando GTK: $THEME_NAME"
        ./change_color.sh -o "$THEME_NAME" <(cat ~/.cache/wal/colors-oomox)

        echo "$THEME_NAME" > "$TEMA_DIR/gtk.txt"
        echo "Guardado gtk.txt para $NOMBRE_TEMA"
    done

    echo "Limpiando Oomox..."
    cd ..
    rm -rf oomox-gtk-theme
else

    echo "Generación de temas GTK con Oomox omitida."
fi

# -------------------------------
# SDDM Astronaut Theme
# -------------------------------
if confirmar "¿Deseas instalar el tema SDDM Astronaut?"; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/keyitdev/sddm-astronaut-theme/master/setup.sh)"
else
    echo "Instalación del tema SDDM Astronaut omitida."
fi

# -------------------------------
# Reinicio opcional
# -------------------------------
if confirmar "¿Deseas reiniciar ahora?"; then
    echo "Reiniciando el sistema en 5 segundos..."
    sleep 5
    reboot
else
    echo "Reinicio cancelado."
fi
