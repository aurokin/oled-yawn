#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

status=0
files=()
while IFS= read -r file; do
  files+=("$file")
done < <(find Package.swift Sources Tests scripts -type f \( -name '*.swift' -o -name '*.sh' \) | sort)

if grep -nE '[[:blank:]]$' "${files[@]}" >/tmp/oled-yawn-lint-trailing 2>/dev/null; then
  echo "Trailing whitespace found:"
  cat /tmp/oled-yawn-lint-trailing
  status=1
fi

if grep -n $'\t' "${files[@]}" >/tmp/oled-yawn-lint-tabs 2>/dev/null; then
  echo "Tab characters found:"
  cat /tmp/oled-yawn-lint-tabs
  status=1
fi

if command -v swift-format >/dev/null 2>&1; then
  swift-format lint --strict --recursive Package.swift Sources Tests
else
  echo "swift-format not found; skipped Swift style lint."
fi

exit "$status"
