#!/bin/bash

MPD_CONF="$HOME/.mpdconf"
MPD_LOG="$HOME/.mpd/log"

echo "🔄 Repornez MPD..."
pkill mpd
sleep 0.5

echo "🟢 Pornez MPD cu config: $MPD_CONF"
mpd "$MPD_CONF" 2>>"$MPD_LOG"

if [ $? -eq 0 ]; then
    echo "✅ MPD pornit"
else
    echo "❌ Eroare! Vezi logul: $MPD_LOG"
fi

# Verifică dacă JBL e conectat
if system_profiler SPBluetoothDataType | grep -qi "JBL"; then
    echo "🎧 JBL pare conectat. Asigură-te că microfonul JBL NU este selectat în Sound → Input."
else
    echo "🎧 JBL nu pare conectat."
fi
