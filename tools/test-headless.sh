#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
godot_bin="${GODOT_BIN:-godot}"

imported=false
for attempt in 1 2 3; do
  if "$godot_bin" --disable-crash-handler --headless --path "$project_dir" --import; then
    imported=true
    break
  fi
  printf 'Importação Godot falhou (tentativa %s/3).\n' "$attempt" >&2
done
if [[ "$imported" != true ]]; then
  exit 1
fi
"$godot_bin" --headless --path "$project_dir" --script res://tests/run.gd
"$godot_bin" --headless --path "$project_dir" --quit-after 2
