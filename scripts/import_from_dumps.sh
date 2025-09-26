#!/usr/bin/env bash
set -euo pipefail
# Builds photon_data from streamed country dumps (retry, integrity, checksum).

. /opt/photon/scripts/common.sh

require_env PHOTON_DATA_DIR
require_env PHOTON_VERSION

PHOTON_JAR="/opt/photon/photon.jar"
[ -f "$PHOTON_JAR" ] || fail "Photon jar not found."

mkdir -p "${PHOTON_DATA_DIR}/builds" "${PHOTON_DATA_DIR}/dumps"

if [ "${FORCE_REIMPORT:-0}" != "1" ] && [ -e "${PHOTON_DATA_DIR}/photon_data" ]; then
  log "Existing photon_data present; skipping (FORCE_REIMPORT!=1)."
  exit 0
fi

[ -n "${PHOTON_COUNTRIES:-}" ] || fail "PHOTON_COUNTRIES is required."

init_checksums

log "Resolving dump URLs for countries: ${PHOTON_COUNTRIES}"
URLS=$(PHOTON_COUNTRIES="${PHOTON_COUNTRIES}" /opt/photon/scripts/resolve_countries.sh)
log "Resolved URLs:"
echo "$URLS" >&2

BUILD_ID=$(timestamp)
BUILD_DIR="${PHOTON_DATA_DIR}/builds/build-${BUILD_ID}"
TMP_COMBINED="${PHOTON_DATA_DIR}/dumps/combined-${BUILD_ID}.jsonl"
mkdir -p "$BUILD_DIR"

if [ "${CHECKSUM_RECORD:-0}" = "1" ]; then
  : > "${PHOTON_DATA_DIR}/dumps/checksums-${BUILD_ID}.txt"
fi

DOWNLOAD_RETRIES="${DOWNLOAD_RETRIES:-5}"
DOWNLOAD_BACKOFF_SECONDS="${DOWNLOAD_BACKOFF_SECONDS:-5}"

download_and_stream() {
  local url="$1"
  CURRENT_DOWNLOAD_URL="$url"
  local attempt=0 tmpfile
  tmpfile=$(mktemp -p /tmp photon_dump_XXXXXX.zst)
  trap 'rm -f "$tmpfile"' RETURN
  local base; base=$(basename "$url")

  while true; do
    attempt=$((attempt+1))
    log "Downloading (attempt ${attempt}/${DOWNLOAD_RETRIES}): $url"
    if curl -fsSL --retry 3 --retry-delay 2 -o "$tmpfile" "$url"; then
      if zstd -t "$tmpfile" >/dev/null 2>&1; then
        log "Zstd integrity OK: $base"
        verify_or_record_checksum "$tmpfile"
        zstd -dc "$tmpfile"
        return 0
      else
        log "Integrity (zstd) failed: $base"
      fi
    else
      log "Download failed: $base"
    fi
    if [ "$attempt" -ge "$DOWNLOAD_RETRIES" ]; then
      fail "Exceeded retries for $base"
    fi
    sleep $(( attempt * DOWNLOAD_BACKOFF_SECONDS ))
  done
}

log "Checksum mode: ALGO=${CHECKSUM_ALGO} VERIFY=${CHECKSUM_VERIFY}"

set -o pipefail
{
  while read -r url; do
    download_and_stream "$url"
  done <<< "$URLS"
} | if [ "${PHOTON_KEEP_COMBINED_JSON:-1}" = "1" ]; then
      tee "$TMP_COMBINED"
    else
      cat
    fi \
  | java ${PHOTON_JAVA_OPTS:-} -jar "$PHOTON_JAR" \
      -nominatim-import \
      -import-file - \
      -languages en,de,fr,ja,it \
      ${PHOTON_IMPORT_EXTRA_ARGS:-}

log "Verifying photon_data directory creation."
if [ ! -d "${BUILD_DIR}/photon_data" ]; then
  if [ -d "photon_data" ]; then
    mv photon_data "${BUILD_DIR}/"
  else
    fail "photon_data not found after import."
  fi
fi

(
  cd "${PHOTON_DATA_DIR}"
  resolve_symlink_atomic "builds/build-${BUILD_ID}/photon_data" "photon_data"
)

log "Retention cleanup..."
cleanup_retention "${PHOTON_DATA_DIR}/builds" "build-*" "${RETENTION_BUILDS:-1}"
cleanup_retention "${PHOTON_DATA_DIR}/dumps" "combined-*.jsonl" "${RETENTION_DUMPS:-1}"

cat > "${PHOTON_DATA_DIR}/.current_build" <<EOF
build_id=${BUILD_ID}
countries=${PHOTON_COUNTRIES}
photon_version=${PHOTON_VERSION}
generated_utc=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
checksum_algo=${CHECKSUM_ALGO}
checksum_verify=${CHECKSUM_VERIFY}
EOF

log "Build ${BUILD_ID} complete."
[ "${CHECKSUM_VERIFY}" = "1" ] && log "All files passed checksum verification."
