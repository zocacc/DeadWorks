#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
godot_bin="${GODOT_BIN:-godot}"
output_dir="$project_dir/builds/windows"
exe="$output_dir/DeadWorks.exe"
pck="$output_dir/DeadWorks.pck"
mkdir -p "$output_dir"

for attempt in 1 2 3; do
  : > "$exe"
  : > "$pck"
  if "$godot_bin" --disable-crash-handler --headless --path "$project_dir" \
      --export-release "Windows Desktop" "$exe" && [[ -s "$exe" && -s "$pck" ]]; then
    printf 'Build Windows pronto: %s e %s\n' "$exe" "$pck"
    exit 0
  fi
  printf 'Exportação Godot falhou (tentativa %s/3).\n' "$attempt" >&2
done
exit 1
