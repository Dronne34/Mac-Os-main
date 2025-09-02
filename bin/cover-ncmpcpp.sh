#!/bin/bash

COVER="/tmp/cover.png"

# Fișierul curent redat de MPD
FILE=$(mpc --format %file% current)

# Folosim calea completă corectă
FULL_PATH="$HOME/$FILE"

# echo "Fișier curent: $FULL_PATH"

rm -f "$COVER"

ffmpeg -y -i "$FULL_PATH" -an -vcodec copy "$COVER" >/tmp/cover-extract.log 2>&1
