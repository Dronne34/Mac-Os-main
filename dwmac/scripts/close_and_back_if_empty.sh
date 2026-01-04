#!/usr/bin/env bash
set -euo pipefail

DW="/opt/homebrew/bin/dwmac"

$DW close --quit-if-last-window >/dev/null 2>&1 || true

sleep 0.4

/bin/bash "$HOME/.config/dwmac/scripts/auto_focus_occupied.sh" >/dev/null 2>&1 || true
