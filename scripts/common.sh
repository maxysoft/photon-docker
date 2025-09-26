#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[%s] %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$*" >&2
}
fail() { log "ERROR: $*"; exit 1; }
require_env() {
  local v="$1"
  [ -n "${!v:-}" ] || fail "Env $v required"
}
timestamp() { date -u +%Y%m%d-%H%M%S; }

cleanup_retention() {
  local base_dir="$1" pattern="$2" retain="${3:-1}"
  [ -d "$base_dir" ] || return 0
  local items
  items=$(ls -1dt "$base_dir"/$pattern 2>/dev/null || true)
  [ -n "$items" ] || return 0
  local c=0
  while read -r line; do
    [ -z "$line" ] && continue
    c=$((c+1))
    if [ "$c" -gt "$retain" ]; then
      log "Pruning: $line"
      rm -rf -- "$line"
    fi
  done <<< "$items"
}

resolve_symlink_atomic() {
  local target="$1" linkname="$2" dir
  dir=$(dirname "$linkname")
  ( cd "$dir"; ln -sfn "$target" "${linkname}.new"; mv -Tf "${linkname}.new" "$linkname" )
}

detect_photon_container_id() {
  docker ps --filter "label=com.docker.compose.service=${PHOTON_SERVICE_LABEL:-photon}" -q | head -n1
}

# --- Checksum Logic ---

declare -A EXPECTED_HASHES
CHECKSUM_VERIFY="${CHECKSUM_VERIFY:-1}"
CHECKSUM_RECORD="${CHECKSUM_RECORD:-1}"
CHECKSUM_STRICT_FILENAMES="${CHECKSUM_STRICT_FILENAMES:-0}"
CHECKSUM_ALGO="${CHECKSUM_ALGO:-md5}"

load_checksums_inline() {
  local data="${CHECKSUM_INLINE:-}"
  [ -n "$data" ] || return 0
  log "Loading inline SHA256 expectations"
  while IFS= read -r line; do
    line="${line%%#*}"
    [ -n "$line" ] || continue
    local h f
    h=$(echo "$line" | awk '{print $1}')
    f=$(echo "$line" | awk '{print $2}')
    [ -n "$h" ] && [ -n "$f" ] && EXPECTED_HASHES["$f"]="$h"
  done <<< "$data"
}

load_checksums_remote() {
  local url="${CHECKSUM_SOURCE_URL:-}"
  [ -n "$url" ] || return 0
  log "Fetching remote SHA256 list: $url"
  local tmp; tmp=$(mktemp)
  curl -fsSL -o "$tmp" "$url" || fail "Cannot download checksum list"
  while IFS= read -r line; do
    line="${line%%#*}"
    [ -n "$line" ] || continue
    local h f
    h=$(echo "$line" | awk '{print $1}')
    f=$(echo "$line" | awk '{print $2}')
    [[ "$f" == photon-dump-* ]] || continue
    [ -n "$h" ] && [ -n "$f" ] && EXPECTED_HASHES["$f"]="$h"
  done < "$tmp"
  rm -f "$tmp"
}

init_checksums() {
  load_checksums_inline
  load_checksums_remote
  if [ "$CHECKSUM_VERIFY" = "1" ] && [ "$CHECKSUM_ALGO" = "sha256" ] && [ "${#EXPECTED_HASHES[@]}" -eq 0 ]; then
    fail "VERIFY=1 but no SHA256 expectations loaded (ALGO=sha256)"
  fi
}

fetch_md5_sidecar() {
  local url="$1" tmp; tmp=$(mktemp)
  if curl -fsSL -o "$tmp" "${url}.md5"; then
    local md5val; md5val=$(awk '{print $1}' "$tmp" | head -n1)
    rm -f "$tmp"
    [[ "$md5val" =~ ^[0-9a-fA-F]{32}$ ]] && { echo "$md5val"; return 0; }
  fi
  rm -f "$tmp" 2>/dev/null || true
  echo ""
}

verify_or_record_checksum() {
  local file="$1" base; base=$(basename "$file")
  local sha256; sha256=$(sha256sum "$file" | awk '{print $1}')

  if [ "$CHECKSUM_RECORD" = "1" ]; then
    echo "${sha256}  ${base}" >> "${PHOTON_DATA_DIR}/dumps/checksums-${BUILD_ID}.txt"
  fi

  case "$CHECKSUM_ALGO" in
    sha256)
      local expect="${EXPECTED_HASHES[$base]:-}"
      if [ -z "$expect" ]; then
        if [ "$CHECKSUM_VERIFY" = "1" ]; then
          if [ "$CHECKSUM_STRICT_FILENAMES" = "1" ]; then
            fail "Missing SHA256 expectation for $base (strict)"
          else
            fail "Missing SHA256 expectation for $base"
          fi
        else
          log "WARN: No SHA256 expectation for $base"
        fi
        return 0
      fi
      [ "$sha256" = "$expect" ] || fail "SHA256 mismatch $base (expected $expect got $sha256)"
      log "SHA256 OK: $base"
      ;;
    md5)
      local md5e md5a
      md5e=$(fetch_md5_sidecar "$CURRENT_DOWNLOAD_URL")
      if [ -z "$md5e" ]; then
        [ "$CHECKSUM_VERIFY" = "1" ] && fail "No MD5 sidecar for $base"
        log "WARN: No MD5 sidecar for $base"
        return 0
      fi
      md5a=$(md5sum "$file" | awk '{print $1}')
      [ "$md5a" = "$md5e" ] || fail "MD5 mismatch $base (expected $md5e got $md5a)"
      log "MD5 OK: $base"
      ;;
    auto)
      local expect="${EXPECTED_HASHES[$base]:-}"
      if [ -n "$expect" ]; then
        [ "$sha256" = "$expect" ] || fail "SHA256 mismatch $base (expected $expect got $sha256)"
        log "SHA256 OK (auto): $base"
        return 0
      fi
      local md5e md5a
      md5e=$(fetch_md5_sidecar "$CURRENT_DOWNLOAD_URL")
      if [ -n "$md5e" ]; then
        md5a=$(md5sum "$file" | awk '{print $1}')
        [ "$md5a" = "$md5e" ] || fail "MD5 mismatch $base (expected $md5e got $md5a)"
        log "MD5 OK (auto fallback): $base"
        return 0
      fi
      if [ "$CHECKSUM_VERIFY" = "1" ]; then
        fail "No SHA256 expectation or MD5 sidecar for $base (auto mode, verify=1)"
      else
        log "WARN: No checksum data for $base (auto, verify=0)"
      fi
      ;;
    *)
      fail "Unknown CHECKSUM_ALGO: $CHECKSUM_ALGO"
      ;;
  esac
}