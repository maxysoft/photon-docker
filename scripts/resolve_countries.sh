#!/usr/bin/env bash
set -euo pipefail

PHOTON_DUMP_BASE="${PHOTON_DUMP_BASE:-https://download1.graphhopper.com/public}"
DUMP_VERSION_TAG="${PHOTON_DUMP_VERSION:-0.7-latest}"

declare -A MAP

MAP[JP]="asia|japan"

MAP[BG]="europe|bulgaria"
MAP[HR]="europe|croatia"
MAP[CZ]="europe|czech-republic"
MAP[DE]="europe|germany"
MAP[GR]="europe|greece"
MAP[HU]="europe|hungary"
MAP[IT]="europe|italy"
MAP[RO]="europe|romania"
MAP[RS]="europe|serbia"
MAP[SI]="europe|slovenia"
MAP[SE]="europe|sweden"

IFS=',' read -r -a codes <<< "
${PHOTON_COUNTRIES:?PHOTON_COUNTRIES required}"

for code in "${codes[@]}"; do
  code_u=$(echo "$code" | tr '[:lower:]' '[:upper:]')
  entry="${MAP[$code_u]:-}"
  if [ -z "$entry" ]; then
    echo "ERROR: No mapping for country code: $code_u" >&2
    exit 1
  fi
  continent="${entry%%|*}"
  slug="${entry##*|}"
  echo "${PHOTON_DUMP_BASE}/${continent}/${slug}/photon-dump-${slug}-${DUMP_VERSION_TAG}.jsonl.zst"
done
