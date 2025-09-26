#!/usr/bin/env bash
set -euo pipefail
. /opt/photon/scripts/common.sh

log "Photon entrypoint started."

if [ "${FORCE_REIMPORT:-0}" = "1" ] || [ ! -e "${PHOTON_DATA_DIR}/photon_data" ]; then
  log "No existing photon_data or FORCE_REIMPORT=1 -> triggering import_from_dumps.sh"
  /opt/photon/scripts/import_from_dumps.sh
else
  log "Existing photon_data found. Skipping import."
fi

cd /opt/photon
log "Launching Photon..."
set -x
exec java ${PHOTON_JAVA_OPTS:-} -jar /opt/photon/photon.jar ${PHOTON_RUN_ARGS:-}
