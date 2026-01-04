#!/usr/bin/env bash
set -euo pipefail

DW="/opt/homebrew/bin/dwmac"

focused_json="$($DW list-workspaces --focused --json 2>/dev/null || true)"
focused_id=$(printf '%s' "$focused_json" | jq -r '
  def wsid($w):
    ($w.id // $w.index // $w.number // $w.workspace // $w.name // empty) | tostring;
  if type == "array" and length > 0 then wsid(.[0])
  elif type == "object" then wsid(.)
  else empty end
')

if [ -z "$focused_id" ] || [ "$focused_id" = "null" ]; then
  all_ws_json="$($DW list-workspaces --all --json 2>/dev/null || true)"
  focused_id=$(printf '%s' "$all_ws_json" | jq -r '
    def wsid($w):
      ($w.id // $w.index // $w.number // $w.workspace // $w.name // empty) | tostring;
    def isfocused($w):
      ($w.focused // $w.is_focused // $w.isFocused // false) == true;
    if type == "array" then .
    elif type == "object" and (.workspaces | type == "array") then .workspaces
    elif type == "object" then [.] else [] end
    | map(select(isfocused(.)))
    | if length > 0 then wsid(.[0]) else empty end
  ')
fi

if [ -z "$focused_id" ] || [ "$focused_id" = "null" ]; then
  exit 0
fi

focused_count="$($DW list-windows --workspace "$focused_id" --count 2>/dev/null || echo 0)"
if [ "${focused_count:-0}" -gt 0 ]; then
  exit 0
fi

all_ws_json="$($DW list-workspaces --all --json 2>/dev/null || true)"
target_id=$(printf '%s' "$all_ws_json" | jq -r '
  def wsid($w):
    ($w.id // $w.index // $w.number // $w.workspace // $w.name // empty) | tostring;
  if type == "array" then .
  elif type == "object" and (.workspaces | type == "array") then .workspaces
  elif type == "object" then [.] else [] end
  | map(wsid(.))
  | map(select(. != null and . != ""))
  | .[]
')

for ws in $target_id; do
  count="$($DW list-windows --workspace "$ws" --count 2>/dev/null || echo 0)"
  if [ "${count:-0}" -gt 0 ]; then
    $DW workspace "$ws" >/dev/null 2>&1 || true
    exit 0
  fi
done

$DW workspace-back-and-forth >/dev/null 2>&1 || true
