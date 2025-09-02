
#!/bin/bash
file=$(/opt/homebrew/bin/mpc --format "%file%" current)
[ -z "$file" ] && exit 0
music_dir="/Users/ciprian/Library/CloudStorage/GoogleDrive-ozy23as@gmail.com/My Drive"
full_path="$music_dir/$file"
# escape spațiile
escaped_path=$(printf '%q' "$full_path")
ffmpeg -y -i "$escaped_path" -an -vcodec copy /tmp/cover.png 2>/dev/null
