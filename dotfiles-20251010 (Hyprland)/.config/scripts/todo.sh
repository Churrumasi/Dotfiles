#!/bin/bash

TODO_FILE="todo.txt"
touch "$TODO_FILE"

agregar_tarea() {
    tarea=$(dialog --inputbox "Escribe la tarea:" 10 50 3>&1 1>&2 2>&3) || return

    prioridad=$(dialog --menu "Elige la prioridad:" 10 40 3 \
        Alta "Urgente" \
        Media "Importante" \
        Baja "Puede esperar" \
        3>&1 1>&2 2>&3) || return

    categoria=$(dialog --menu "Elige la categoría:" 10 40 3 \
        Trabajo "Laboral" \
        Personal "Tareas personales" \
        Otro "Otro tipo" \
        3>&1 1>&2 2>&3) || return

    fecha=$(date '+%Y-%m-%d')
    echo "[ ] $tarea (Creada: $fecha) [Prioridad: $prioridad] [Categoría: $categoria]" >> "$TODO_FILE"
}

mostrar_tareas() {
    if [[ ! -s "$TODO_FILE" ]]; then
        dialog --msgbox "No hay tareas." 10 40
    else
        tareas=$(nl -w2 -s'. ' "$TODO_FILE")
        dialog --title "Todas las tareas" --msgbox "$tareas" 20 80
    fi
}

filtrar_tareas() {
    filtro=$(dialog --menu "¿Cómo quieres filtrar?" 10 40 2 \
        Prioridad "Filtrar por prioridad" \
        Categoria "Filtrar por categoría" \
        3>&1 1>&2 2>&3) || return

    if [[ $filtro == "Prioridad" ]]; then
        valor=$(dialog --menu "Selecciona prioridad:" 10 40 3 Alta "Urgente" Media "Importante" Baja "Puede esperar" 3>&1 1>&2 2>&3) || return
        tareas=$(grep "\[Prioridad: $valor\]" "$TODO_FILE")
    elif [[ $filtro == "Categoria" ]]; then
        valor=$(dialog --menu "Selecciona categoría:" 10 40 3 Trabajo "Laboral" Personal "Tareas personales" Otro "Otro tipo" 3>&1 1>&2 2>&3) || return
        tareas=$(grep "\[Categoría: $valor\]" "$TODO_FILE")
    fi

    if [[ -z "$tareas" ]]; then
        dialog --msgbox "No se encontraron tareas para ese filtro." 10 50
    else
        dialog --title "Tareas filtradas" --msgbox "$tareas" 20 80
    fi
}

marcar_completada() {
    opciones=$(grep -n "^\[ \]" "$TODO_FILE" | sed 's/:/ /' | awk '{print $1 " \"" substr($0, index($0,$2)) "\"" }' ORS=' ')
    if [ -z "$opciones" ]; then
        dialog --msgbox "No hay tareas pendientes." 10 40
    else
        id=$(eval dialog --menu \"Marcar tarea completada\" 20 80 10 $opciones 3>&1 1>&2 2>&3)
        if [ -n "$id" ]; then
            sed -i "${id}s/^\[ \]/[x]/" "$TODO_FILE"
        fi
    fi
}

eliminar_tarea() {
    opciones=$(nl -w2 -s' ' "$TODO_FILE" | awk '{print $1 " \"" substr($0, index($0,$2)) "\"" }' ORS=' ')
    if [ -z "$opciones" ]; then
        dialog --msgbox "No hay tareas." 10 40
    else
        id=$(eval dialog --menu \"Eliminar tarea\" 20 80 10 $opciones 3>&1 1>&2 2>&3)
        if [ -n "$id" ]; then
            sed -i "${id}d" "$TODO_FILE"
        fi
    fi
}

while true; do
    opcion=$(dialog --clear --backtitle "To-Do List Avanzado" \
        --title "Menú principal" \
        --menu "Selecciona una opción:" 16 60 7 \
        1 "Ver todas las tareas" \
        2 "Agregar tarea" \
        3 "Marcar como completada" \
        4 "Eliminar tarea" \
        5 "Filtrar tareas" \
        6 "Salir" \
        3>&1 1>&2 2>&3)

    case $opcion in
        1) mostrar_tareas ;;
        2) agregar_tarea ;;
        3) marcar_completada ;;
        4) eliminar_tarea ;;
        5) filtrar_tareas ;;
        6) clear; exit 0 ;;
    esac
done
