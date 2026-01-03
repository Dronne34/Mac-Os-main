#!/bin/zsh

COVER="/tmp/cover.png"
CHAFA_BIN=""
if [[ -x /opt/homebrew/bin/chafa ]]; then
  CHAFA_BIN="/opt/homebrew/bin/chafa"
else
  CHAFA_BIN="$(command -v chafa 2>/dev/null)"
fi
LAST_HASH=""

function show_cover {
  if [[ -f "$COVER" ]]; then
    CURRENT_HASH=$(md5sum "$COVER" | cut -d' ' -f1)

    if [[ "$CURRENT_HASH" != "$LAST_HASH" ]]; then
      kitty +kitten icat --clear
      if [[ -n "$CHAFA_BIN" ]]; then
        "$CHAFA_BIN" --size 25x25 --align center "$COVER"
      else
        echo "chafa not found in PATH or /opt/homebrew/bin"
        return 1
      fi
      LAST_HASH="$CURRENT_HASH"
    fi
  else
    kitty +kitten icat --clear
    # echo "❌ Nicio copertă găsită în $COVER"
  fi
}

# Prima afișare
show_cover

while true; do
  # Așteaptă schimbare melodie în MPD
  # mpc idle player

  # Pauză scurtă pentru ca extract-cover.sh să scrie fișierul
  sleep 0.3

  # Reafișează coperta
  show_cover
done
