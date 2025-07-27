#!/bin/bash

# Obține calea completă a fișierului curent din MPD
# file=$(mpc --format "%file%" current)
file=$(/opt/homebrew/bin/mpc --format "%file%" current)

# Dacă nu rulează nimic, ieși
# if [ -z "$file" ]; then
# echo "Niciun fișier redat în prezent."
# exit 1
# fi

# Construiește calea completă către fișier în funcție de setarea music_directory din mpd.conf
# music_dir="$HOME/Music" # modifică dacă ai alta locație
music_dir="/Users/ciprian/Library/Mobile Documents/com~apple~CloudDocs/Muzica/"
full_path="$music_dir/$file"

# Folosește ffmpeg pentru a extrage cover-ul
ffmpeg -y -i "$full_path" -an -vcodec copy /tmp/cover.png 2>/dev/null

# Verifică dacă s-a extras corect
# if [ -f /tmp/cover.png ]; then
# echo "Cover salvat în /tmp/cover.png"
# else
# echo "Nu s-a putut extrage cover art."
# fi
