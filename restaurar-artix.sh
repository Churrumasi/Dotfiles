#!/bin/bash
# restaurar.sh - Script interactivo para restaurar dotfiles y configuración en Artix Linux (runit)
# Autor: Churrumasi
# Adaptación: ChatGPT
#
# Este script permite restaurar la configuración de usuario, paquetes, servicios y temas
# desde un backup generado por backup.sh. Proporciona opciones interactivas para cada paso
# importante del proceso de restauración, permitiendo al usuario decidir qué restaurar.

set -euo pipefail

# -------------------------------
# Función para confirmar acciones (sí/no)
# -------------------------------
confirmar() {
    local pregunta="${1:-¿Continuar?}"
    read -rp "$pregunta (s/n): " RESP
    [[ "$RESP" =~ ^[sS]$ ]]
}

# -------------------------------
# Función para ejecutar comandos con cd temporal
# -------------------------------
run_in_dir() {
    local dir="$1"
    shift
    ( cd "$dir" && "$@" )
}

# -------------------------------
# Función para instalar lista de paquetes
# -------------------------------
instalar_lista_paquetes() {
    local archivo="$1"
    local gestor="$2"

    [[ -f "$archivo" ]] || return 0

    # Filtra líneas vacías o comentarios
    local tmp
    tmp="$(mktemp)"
    grep -vE '^\s*#|^\s*$' "$archivo" > "$tmp" || true

    if [[ ! -s "$tmp" ]]; then
        echo "No hay paquetes válidos en $archivo"
        rm -f "$tmp"
        return 0
    fi

    if [[ "$gestor" == "pacman" ]]; then
        xargs -r -a "$tmp" sudo pacman -S --needed --noconfirm --
    else
        if ! command -v yay &>/dev/null; then
            echo "yay no está instalado, no se pueden instalar paquetes AUR."
        else
            xargs -r -a "$tmp" yay -S --needed --noconfirm --
        fi
    fi

    rm -f "$tmp"
}
# -------------------------------
# Función para habilitar servicios runit
# -------------------------------
habilitar_servicio_runit() {
    local servicio="$1"
    local origen=""
    local destino="/run/runit/service/$servicio"

    for base in /etc/runit/sv /etc/sv /run/runit/service /var/service; do
        if [[ -d "$base/$servicio" ]]; then
            origen="$base/$servicio"
            break
        fi
    done

    if [[ -z "$origen" ]]; then
        echo "⚠️ Servicio no encontrado: $servicio"
        return 0
    fi

    sudo mkdir -p /run/runit/service

    if [[ -L "$destino" ]]; then
        echo "✔️ Servicio ya habilitado: $servicio"
    else
        sudo ln -s "$origen" "$destino"
        echo "✔️ Habilitado: $servicio"
    fi
}

# -------------------------------
# ➕ Agregar Chaotic AUR (repositorio de paquetes)
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
        echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf >/dev/null
    else
        echo "chaotic-aur ya está en /etc/pacman.conf, omitiendo."
    fi

    echo "Sincronizando e iniciando actualización..."
    sudo pacman -Syu
fi

# -------------------------------
# 🛠 Instalar yay (AUR helper)
# -------------------------------
if confirmar "¿Quieres verificar/instalar yay?"; then
    if ! command -v yay &>/dev/null; then
        echo "Instalando yay..."
        sudo pacman -S --needed --noconfirm git base-devel
        git clone https://aur.archlinux.org/yay-bin.git
        run_in_dir yay-bin makepkg -si --noconfirm
        rm -rf yay-bin
    else
        echo "yay ya está instalado."
    fi
fi

# -------------------------------
# 🎨 Instalar temas de GRUB
# -------------------------------
if confirmar "¿Deseas instalar los temas de GRUB?"; then
    git clone https://github.com/ChrisTitusTech/Top-5-Bootloader-Themes
    run_in_dir Top-5-Bootloader-Themes sudo ./install.sh
    rm -rf Top-5-Bootloader-Themes
fi

# -------------------------------
# 🌀 Instalar y configurar Zsh + Oh My Zsh + Powerlevel10k
# -------------------------------
if confirmar "¿Quieres instalar Zsh y Oh My Zsh?"; then
    if ! command -v zsh &>/dev/null; then
        sudo pacman -S --needed --noconfirm zsh
    fi

    ZSH_PATH="$(command -v zsh)"
    if ! grep -qF "$ZSH_PATH" /etc/shells; then
        echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
    fi

    if [[ "$SHELL" != "$ZSH_PATH" ]]; then
        chsh -s "$ZSH_PATH" || true
    fi

    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi

    if command -v yay &>/dev/null; then
        yay -S --needed --noconfirm zsh-theme-powerlevel10k-git
    fi

    if [[ -f "$HOME/.zshrc" ]] && ! grep -q "powerlevel10k.zsh-theme" "$HOME/.zshrc"; then
        echo 'source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme' >> "$HOME/.zshrc"
    fi

    if [[ -f "$HOME/.cache/wal/colors-tty.sh" ]]; then
        chmod +x "$HOME/.cache/wal/colors-tty.sh"
        if ! grep -q "colors-tty.sh" "$HOME/.zshrc"; then
            echo "source ~/.cache/wal/colors-tty.sh" >> "$HOME/.zshrc"
        fi
    fi
fi

# -------------------------------
# 🎨 Instalar tema de iconos Tela Circle
# -------------------------------
if confirmar "¿Deseas instalar el tema de iconos Tela Circle?"; then
    if command -v yay &>/dev/null; then
        echo "Instalando tema de iconos Tela Circle..."
        yay -S --needed --noconfirm tela-circle-icon-theme
    else
        echo "yay no está instalado, se omite Tela Circle."
    fi
else
    echo "Tema de iconos omitido."
fi

# -------------------------------
# 📁 Selección de backup para restaurar
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
        if [[ -n "${LATEST_BACKUP:-}" ]]; then
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
# 📦 Instalación de paquetes desde el backup
# -------------------------------
if confirmar "¿Deseas instalar los paquetes del backup?"; then
    if [[ -f "$LATEST_BACKUP/pkglist-pacman.txt" ]]; then
        instalar_lista_paquetes "$LATEST_BACKUP/pkglist-pacman.txt" "pacman"
    else
        echo "No se encontró pkglist-pacman.txt en $LATEST_BACKUP"
    fi

    if [[ -f "$LATEST_BACKUP/pkglist-aur.txt" ]]; then
        instalar_lista_paquetes "$LATEST_BACKUP/pkglist-aur.txt" "aur"
    else
        echo "No se encontró pkglist-aur.txt en $LATEST_BACKUP"
    fi
fi

# -------------------------------
# 🎨 Instalar temas de Rofi
# -------------------------------
if confirmar "¿Deseas instalar los temas de rofi?"; then
    if [[ ! -d "$HOME/rofi" ]]; then
        git clone --depth=1 https://github.com/adi1090x/rofi.git
        run_in_dir rofi chmod +x setup.sh
        run_in_dir rofi ./setup.sh
        rm -rf rofi
    else
        echo "Carpeta 'rofi' ya existe, saltando."
    fi
fi

# -------------------------------
# 🗂️ Restaurar ~/.config
# -------------------------------
if confirmar "¿Deseas restaurar la carpeta ~/.config?"; then
    mkdir -p "$HOME/.config"
    if [[ -d "$LATEST_BACKUP/.config" ]]; then
        cp -a "$LATEST_BACKUP/.config/." "$HOME/.config/"
        echo "✔️ Restaurada ~/.config"
    else
        echo "No se encontró .config en el backup."
    fi
fi

# -------------------------------
# 🏠 Restaurar dotfiles personales
# -------------------------------
if confirmar "¿Deseas restaurar los dotfiles personales?"; then
    for file in ".zshrc" ".bashrc" ".xinitrc" ".bash_profile" ".profile" ".p10k.zsh"; do
        if [[ -f "$LATEST_BACKUP/$file" ]]; then
            cp -a "$LATEST_BACKUP/$file" "$HOME/"
            echo "Restaurado $file"
        else
            echo "$file no encontrado en $LATEST_BACKUP"
        fi
    done
fi

# -------------------------------
# 🛠️ Restaurar servicios personalizados de runit
# -------------------------------
if confirmar "¿Deseas restaurar los servicios personalizados de runit?"; then
    if [[ -d "$LATEST_BACKUP/runit-services" ]]; then
        sudo mkdir -p /etc/runit/sv

        for service_dir in "$LATEST_BACKUP/runit-services"/*; do
            [[ -d "$service_dir" ]] || continue
            service_name=$(basename "$service_dir")

            sudo mkdir -p "/etc/runit/sv/$service_name"
            sudo rsync -a --delete --exclude='supervise' "$service_dir/" "/etc/runit/sv/$service_name/"

            echo "✔️ Servicio restaurado: $service_name"
        done
    else
        echo "No se encontró la carpeta runit-services en $LATEST_BACKUP"
    fi
fi

# -------------------------------
# ⚙️ Activar servicios runit
# -------------------------------
if confirmar "¿Deseas activar servicios guardados?"; then
    if [[ -f "$LATEST_BACKUP/enabled-services.txt" ]]; then
        while IFS= read -r service; do
            [[ -z "$service" ]] && continue
            [[ "$service" =~ ^# ]] && continue
            habilitar_servicio_runit "$service"
        done < "$LATEST_BACKUP/enabled-services.txt"
    else
        echo "enabled-services.txt no encontrado en $LATEST_BACKUP"
    fi
fi
# -------------------------------
# 🧩 Configurar Git
# -------------------------------
if confirmar "¿Deseas configurar Git con tus datos?"; then
    git config --global user.name "Churrumasi"
    git config --global user.email "j63954923@gmail.com"
fi

# -------------------------------
# 🎨 Generar temas GTK con Oomox
# -------------------------------
if confirmar "¿Quieres generar temas GTK con Oomox para todos los temas de ~/.config/temas?"; then
    echo "Instalando dependencias para Oomox..."
    sudo pacman -S --needed --noconfirm bash grep sed bc glib2 gdk-pixbuf2 sassc librsvg

    git clone https://github.com/themix-project/oomox-gtk-theme.git
    cd oomox-gtk-theme

    for TEMA_DIR in "$HOME/.config/temas"/*; do
        [[ -d "$TEMA_DIR" ]] || continue
        NOMBRE_TEMA=$(basename "$TEMA_DIR")

        FONDO="$TEMA_DIR/fondo.png"
        [[ -f "$FONDO" ]] || { echo "Sin fondo en $NOMBRE_TEMA, omitiendo..."; continue; }

        echo "Aplicando wal con fondo: $FONDO"
        wal -i "$FONDO"

        THEME_NAME="my-wal-theme-${NOMBRE_TEMA,,}"
        echo "Generando GTK: $THEME_NAME"
        ./change_color.sh -o "$THEME_NAME" <(cat ~/.cache/wal/colors-oomox)

        echo "$THEME_NAME" > "$TEMA_DIR/gtk.txt"
        echo "Guardado gtk.txt para $NOMBRE_TEMA"
    done

    cd ..
    rm -rf oomox-gtk-theme
else
    echo "Generación de temas GTK con Oomox omitida."
fi

# -------------------------------
# 🎨 Instalar tema SDDM Astronaut
# -------------------------------
if confirmar "¿Deseas instalar el tema SDDM Astronaut?"; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/keyitdev/sddm-astronaut-theme/master/setup.sh)"
else
    echo "Instalación del tema SDDM Astronaut omitida."
fi

# -------------------------------
# 🔄 Reinicio opcional del sistema
# -------------------------------
if confirmar "¿Deseas reiniciar ahora?"; then
    echo "Reiniciando el sistema en 5 segundos..."
    sleep 5
    sudo reboot
else
    echo "Reinicio cancelado."
fi