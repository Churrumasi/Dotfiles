#!/bin/bash

cliphist list | rofi -dmenu -theme ~/.config/rofi/launchers/type-2/style-1.rasi | cliphist decode | wl-copy
