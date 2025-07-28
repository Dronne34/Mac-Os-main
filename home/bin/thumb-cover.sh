#!/bin/bash

OUTPUT_DIR="$HOME/muzica_2pac"
LISTA="lista.txt"
TMP_THUMB="/tmp/yt_thumb"
TMP_JPG="/tmp/yt_thumb.jpg"

mkdir -p "$OUTPUT_DIR"

while IFS= read -r line || [ -n "$line" ]; do
    TITLU=$(basename "$line" .mp3 | xargs)
    MP3_FILE="$OUTPUT_DIR/$TITLU.mp3"

    if [[ ! -f "$MP3_FILE" ]]; then
        echo "❌ Fișier inexistent: $MP3_FILE"
        continue
    fi

    echo "🎯 Procesare: $TITLU"

    # Extragem artistul și titlul (format: Artist - Titlu)
    ARTIST=$(echo "$TITLU" | cut -d'-' -f1 | xargs)
    TITLE=$(echo "$TITLU" | cut -d'-' -f2- | xargs)

    # Album = "NumeArtist Collection"
    ALBUM="${ARTIST} Collection"

    # Obține thumbnail de pe YouTube
    THUMB_URL=$(yt-dlp --skip-download --print "%(thumbnail)s" "ytsearch1:$TITLU" | head -n1)

    if [[ -z "$THUMB_URL" ]]; then
        echo "⚠️  Nu am găsit thumbnail pentru: $TITLU"
        continue
    fi

    # Descarcă thumbnail
    curl -s -L -o "$TMP_THUMB" "$THUMB_URL"

    MIME_TYPE=$(file --mime-type -b "$TMP_THUMB")

    # Convertim în JPEG dacă este webp
    if [[ "$MIME_TYPE" == "image/webp" ]]; then
        if command -v convert &>/dev/null; then
            convert "$TMP_THUMB" "$TMP_JPG"
            THUMB_FINAL="$TMP_JPG"
        else
            echo "❌ Lipsește 'convert' (ImageMagick) pentru a converti din WebP"
            continue
        fi
    elif [[ "$MIME_TYPE" == "image/jpeg" || "$MIME_TYPE" == "image/png" ]]; then
        cp "$TMP_THUMB" "$TMP_JPG"
        THUMB_FINAL="$TMP_JPG"
    else
        echo "❌ Format necunoscut pentru thumbnail: $MIME_TYPE"
        continue
    fi

    TEMP_MP3="${MP3_FILE%.mp3}_with_thumb.mp3"

    ffmpeg -y -i "$MP3_FILE" -i "$THUMB_FINAL" \
        -map 0 -map 1 \
        -c copy \
        -id3v2_version 3 \
        -metadata title="$TITLE" \
        -metadata artist="$ARTIST" \
        -metadata album="$ALBUM" \
        -metadata:s:v title="Album cover" \
        -metadata:s:v comment="Cover (front)" \
        -disposition:v:1 attached_pic \
        "$TEMP_MP3"

    if [[ -f "$TEMP_MP3" ]]; then
        mv "$TEMP_MP3" "$MP3_FILE"
        echo "✅ Taguri completate: $MP3_FILE"
    else
        echo "❌ Eroare la procesare: $TITLU"
    fi

done <"$LISTA"

rm -f "$TMP_THUMB" "$TMP_JPG"
