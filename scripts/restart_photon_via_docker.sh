#!/usr/bin/env bash
set -euo pipefail
. /opt/photon/scripts/common.sh

cid=$(detect_photon_container_id)
if [ -z "$cid" ]; then
  log "No running photon container found with label com.docker.compose.service=${PHOTON_SERVICE_LABEL:-photon}"
  exit 1
fi
log "Restarting photon container id=$cid"
docker restart "$cid" >/dev/null
log "Photon container restarted."
