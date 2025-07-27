#!/usr/bin/env sh

color=${1:-"31"}
space=${2:-" "}
zero=${3:-" "}
one=${4:-"█"}

cmd=$(cat <<EOF
  echo "\033[${color}m" ;
  binclock --color=off | sed -e 's/0/${zero}/g' -e 's/1/${one}/g' -e 's/ /${space}/g' | sed -E -e 's/(.)/\1\1\1\1/g' -e 's/^(.*)$/\1\n\1/g' ;
  echo "\033[0m"
EOF
)

watch -n1 -t -c $cmd