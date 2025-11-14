# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
source ~/.cache/wal/colors-tty.sh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
actualizar() {
    echo "Actualizando sistema..."
    sudo pacman -Syu --noconfirm
}
source ~/.cache/wal/colors-tty.sh
xinput set-prop "SYNA2BA6:00 06CB:CE2D Touchpad" "libinput Disable While Typing Enabled" 0
# historial
HISTFILE=~/.zsh_history      # archivo de historial
HISTSIZE=10000               # cuántas líneas mantener en memoria
SAVEHIST=10000               # cuántas líneas guardar en el archivo

# opciones para que no se sobrescriba y se vaya guardando inmediatamente
setopt APPEND_HISTORY        # no sobrescribir archivo, añadir al final
setopt INC_APPEND_HISTORY    # ir escribiendo cada comando en el archivo
setopt SHARE_HISTORY         # compartir/mezclar historial con otras sesiones

# limpieza/optimización
setopt HIST_REDUCE_BLANKS    # evita entradas con muchos espacios en blanco
setopt HIST_IGNORE_DUPS      # evita duplicados inmediatos
setopt EXTENDED_HISTORY      # guarda timestamps (útil, opcional)
