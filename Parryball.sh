#!/bin/sh
printf '\033c\033]0;%s\a' Parryball
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Parryball.x86_64" "$@"
