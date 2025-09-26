#!/usr/bin/env bash
set -euo pipefail

. /opt/photon/scripts/common.sh

export FORCE_REIMPORT=1
/opt/photon/scripts/import_from_dumps.sh

if [ "${1:-}" = "--auto" ]; then
  log "Automatic mode: attempting container restart via Docker socket."
  /opt/photon/scripts/restart_photon_via_docker.sh || log "Restart attempt failed (non-fatal)."
else
  log "Manual mode: restart photon container to load new index."
fi
