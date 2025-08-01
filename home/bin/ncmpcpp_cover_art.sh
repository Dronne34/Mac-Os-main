#!/bin/bash
# Cover art script for ncmpcpp-icat

# SETTINGS
music_library="$HOME/Music"
fallback_image="$HOME/.ncmpcpp/ncmpcpp-icat/img/fallback.png"
padding_top=2
padding_bottom=4
padding_right=0
max_width=0
reserved_playlist_cols=30
reserved_cols_in_percent="false"
force_square="true"
square_alignment="top"
left_aligned="false"
padding_left=

# Only set this if the geometries are wrong or ncmpcpp shouts at you to do it.
# Visually select/highlight a character on your terminal, zoom in an image
# editor and count how many pixels a character's width and height are.
font_height=
font_width=

main() {
  kill_previous_instances >/dev/null 2>&1
  find_cover_image >/dev/null 2>&1
  display_cover_image 2>/dev/null
  # detect_window_resizes   >/dev/null 2>&1
  # notify-send -u low -i ${cover_path} " Now Playing" "`mpc current`" # uncomment for track change notifications
}

# ==== Main functions =========================================================

kill_previous_instances() {
  script_name=$(basename "$0")
  for pid in $(pidof -x "$script_name"); do
    if [ "$pid" != $$ ]; then
      kill -15 "$pid"
    fi
  done
}

find_cover_image() {

  # First we check if the audio file has an embedded album art
  ext="$(mpc --format %file% current | sed 's/^.*\.//')"
  if [ "$ext" = "flac" ]; then
    # since FFMPEG cannot export embedded FLAC art we use metaflac
    metaflac --export-picture-to=/tmp/mpd_cover.jpg \
      "$(mpc --format "$music_library"/%file% current)" &&
      cover_path="/tmp/mpd_cover.jpg" && return
  else
    ffmpeg -y -i "$(mpc --format "$music_library"/%file% | head -n 1)" \
      /tmp/mpd_cover.jpg &&
      cover_path="/tmp/mpd_cover.jpg" && return
  fi

  # If no embedded art was found we look inside the music file's directory
  album="$(mpc --format %album% current)"
  file="$(mpc --format %file% current)"
  album_dir="${file%/*}"
  album_dir="$music_library/$album_dir"
  found_covers="$(find "$album_dir" -type d -exec find {} -maxdepth 1 -type f \
    -iregex ".*/.*\(${album}\|cover\|folder\|artwork\|front\).*[.]\\(jpe?g\|png\|gif\|bmp\)" \;)"
  cover_path="$(echo "$found_covers" | head -n1)"
  notify-send $cover_path
  if [ -n "$cover_path" ]; then
    return
  fi

  # If we still failed to find a cover image, we use the fallback
  if [ -z "$cover_path" ]; then
    cover_path=$fallback_image
  fi
}

display_cover_image() {
  kitty +kitten icat --clear --silent
  compute_geometry

  [[ $left_aligned == "true" ]] && alignment=left || alignment=right

  send_to_icat \
    "--silent" \
    "--scale-up" \
    "--align ${alignment}" \
    "--stdin no" \
    "--transfer-mode stream" \
    "--place ${icat_width}x${icat_height}@${icat_left}x${padding_top}" \
    "$cover_path"
}

detect_window_resizes() {
  {
    trap 'display_cover_image' WINCH
    while :; do sleep 5; done
  } &
}

# ==== Helper functions =========================================================

compute_geometry() {
  unset LINES COLUMNS # Required in order for tput to work in a script
  term_lines=$(tput lines)
  term_cols=$(tput cols)
  if [ -z "$font_height" ] || [ -z "$font_height" ]; then
    guess_font_size
  fi

  icat_height=$((term_lines - padding_top - padding_bottom))
  # Because Ueberzug uses characters as a unit we must multiply
  # the line count (height) by the font size ratio in order to
  # obtain an equivalent width in column count
  icat_width=$((icat_height * font_height / font_width))
  icat_left=$((term_cols - icat_width - padding_right))

  if [ "$left_aligned" = "true" ]; then
    compute_geometry_left_aligned
  else
    compute_geometry_right_aligned
  fi

  apply_force_square_setting
}

compute_geometry_left_aligned() {
  icat_left=$padding_left
  max_width_chars=$((term_cols * max_width / 100))
  if [ "$max_width" != 0 ] &&
    [ $((icat_width + padding_right + padding_left)) -gt "$max_width_chars" ]; then
    icat_width=$((max_width_chars - padding_left - padding_right))
  fi
}

compute_geometry_right_aligned() {
  if [ "$reserved_cols_in_percent" = "true" ]; then
    icat_left_percent=$(printf "%.0f\n" $(calc "$icat_left" / "$term_cols" '*' 100))
    if [ "$icat_left_percent" -lt "$reserved_playlist_cols" ]; then
      icat_left=$((term_cols * reserved_playlist_cols / 100))
      icat_width=$((term_cols - icat_left - padding_right))
    fi
  else
    if [ "$icat_left" -lt "$reserved_playlist_cols" ]; then
      icat_left=$reserved_playlist_cols
      icat_width=$((term_cols - icat_left - padding_right))
    fi

  fi

  if [ "$max_width" != 0 ] && [ "$icat_width" -gt "$max_width" ]; then
    icat_width=$max_width
    icat_left=$((term_cols - icat_width - padding_right))
  fi
}

apply_force_square_setting() {
  if [ $force_square = "true" ]; then
    icat_height=$((icat_width * font_width / font_height))
    case "$square_alignment" in
    center)
      area=$((term_lines - padding_top - padding_bottom))
      padding_top=$((padding_top + area / 2 - icat_height / 2))
      ;;
    bottom)
      padding_top=$((term_lines - padding_bottom - icat_height))
      ;;
    *) ;;
    esac
  fi
}

guess_font_size() {
  # A font width and height estimate is required to
  # properly compute the cover width (in columns).
  # We are reproducing the arithmetic used by Ueberzug
  # to guess font size.
  # https://github.com/seebye/ueberzug/blob/master/ueberzug/terminal.py#L24

  guess_terminal_pixelsize

  approx_font_width=$((term_width / term_cols))
  approx_font_height=$((term_height / term_lines))

  term_xpadding=$(((-approx_font_width * term_cols + term_width) / 2))
  term_ypadding=$(((-approx_font_height * term_lines + term_height) / 2))

  font_width=$(((term_width - 2 * term_xpadding) / term_cols))
  font_height=$(((term_height - 2 * term_ypadding) / term_lines))
}

guess_terminal_pixelsize() {
  # We are re-using the same Python snippet that
  # Ueberzug utilizes to retrieve terminal window size.
  # https://github.com/seebye/ueberzug/blob/master/ueberzug/terminal.py#L10

  python <<END
import sys, struct, fcntl, termios

def get_geometry():
    fd_pty = sys.stdout.fileno()
    farg = struct.pack("HHHH", 0, 0, 0, 0)
    fretint = fcntl.ioctl(fd_pty, termios.TIOCGWINSZ, farg)
    rows, cols, xpixels, ypixels = struct.unpack("HHHH", fretint)
    return "{} {}".format(xpixels, ypixels)

output = get_geometry()
f = open("/tmp/ncmpcpp_geometry.txt", "w")
f.write(output)
f.close()
END

  # ioctl doesn't work inside $() for some reason so we
  # must use a temporary file
  term_width=$(awk '{print $1}' /tmp/ncmpcpp_geometry.txt)
  term_height=$(awk '{print $2}' /tmp/ncmpcpp_geometry.txt)
  rm "/tmp/ncmpcpp_geometry.txt"

  if ! is_font_size_successfully_computed; then
    echo "Failed to guess font size, try setting it in ncmpcpp_cover_art.sh settings"
  fi
}

is_font_size_successfully_computed() {
  [ -n "$term_height" ] && [ -n "$term_width" ] &&
    [ "$term_height" != "0" ] && [ "$term_width" != "0" ]
}

calc() {
  awk "BEGIN{print $*}"
}

send_to_icat() {
  # old_IFS="$IFS"

  # Ueberzug's "simple parser" uses tab-separated
  # keys and values so we separate words with tabs
  # and send the result to the wrapper's FIFO
  # IFS="$(printf "\t")"
  echo "$*" >"$FIFO_ICAT"

  # IFS=${old_IFS}
}

main
