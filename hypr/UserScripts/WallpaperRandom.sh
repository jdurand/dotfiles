#!/bin/bash

# Random wallpaper script for waybar
WALLPAPERS_DIR="$HOME/Pictures/wallpapers"
RANDOM_PIC=$(find "$WALLPAPERS_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | shuf -n 1)

if [ -n "$RANDOM_PIC" ]; then
    OUTPUT=$(~/.dotfiles/hypr/scripts/get-monitor)
    hyprctl hyprpaper unload all >/dev/null
    hyprctl hyprpaper preload "$RANDOM_PIC"
    hyprctl hyprpaper wallpaper "$OUTPUT,$RANDOM_PIC"
fi