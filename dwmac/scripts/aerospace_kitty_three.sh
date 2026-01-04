#!/bin/bash
set -euo pipefail

open -a kitty.app -n
sleep 0.4

aerospace split horizontal
open -a kitty.app -n
sleep 0.4

aerospace focus right

aerospace split vertical
open -a kitty.app -n
