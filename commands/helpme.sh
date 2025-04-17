#!/usr/bin/env bash
function helpme() {
  echo "🧭 Enabled commands:"
  while IFS= read -r cmd; do
    [[ "$cmd" =~ ^#|^$ ]] && continue
    echo "  - $cmd"
  done < "/c/src/bash_script/enabled_commands.conf"
}
