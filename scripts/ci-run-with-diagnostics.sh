#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: $0 <name> <command> [args...]" >&2
  exit 64
fi

NAME="$1"
shift
TAIL_LINES="${LOUPE_CI_TAIL_LINES:-120}"
DIAGNOSTIC_GLOBS="${LOUPE_CI_DIAGNOSTICS:-/tmp/loupe-*}"

"$@" || STATUS=$?
STATUS="${STATUS:-0}"
if [[ "$STATUS" -eq 0 ]]; then
  exit 0
fi

echo "::error title=${NAME} failed::Command exited with status ${STATUS}"
echo "::group::Loupe diagnostics"
for pattern in $DIAGNOSTIC_GLOBS; do
  matches=( $pattern )
  if [[ "${matches[0]}" == "$pattern" && ! -e "${matches[0]}" ]]; then
    continue
  fi

  for path in "${matches[@]}"; do
    if [[ -d "$path" ]]; then
      echo "--- $path/ ---"
      find "$path" -maxdepth 2 -type f | sort | head -50
      continue
    fi

    if [[ ! -f "$path" ]]; then
      continue
    fi

    byte_count="$(wc -c <"$path" | tr -d ' ')"
    echo "--- $path (${byte_count} bytes) ---"
    case "$path" in
      *.json|*.log|*.txt)
        tail -n "$TAIL_LINES" "$path" || true
        ;;
      *)
        echo "skipping binary or unsupported diagnostic preview"
        ;;
    esac
  done
done
echo "::endgroup::"

exit "$STATUS"
