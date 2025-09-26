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

IFS=',' read -r -a codes <<< "${PHOTON_COUNTRIES:?PHOTON_COUNTRIES required}"

urls=()
for raw in "${codes[@]}"; do
  code=$(echo "$raw" | tr -d '[:space:]')
  [ -z "$code" ] && continue
  code_u=$(echo "$code" | tr '[:lower:]' '[:upper:]')
  entry="${MAP[$code_u]:-}"
  if [ -z "$entry" ]; then
    echo "ERROR: No mapping for country code: $code_u" >&2
    exit 1
  fi
  continent="${entry%%|*}"
  slug="${entry##*|}"
  urls+=("${PHOTON_DUMP_BASE}/${continent}/${slug}/photon-dump-${slug}-${DUMP_VERSION_TAG}.jsonl.zst")
done

if [ "${#urls[@]}" -eq 0 ]; then
  echo "ERROR: No valid country codes resolved from PHOTON_COUNTRIES='${PHOTON_COUNTRIES}'" >&2
  exit 1
fi

printf '%s\n' "${urls[@]}"
