#!/usr/bin/env bash
set -euo pipefail
. /opt/photon/scripts/common.sh

CRON_EXPR="${REBUILD_CRON:-0 3 1 * *}"
SCRIPT="/opt/photon/scripts/rebuild_from_dumps.sh --auto"
LOGFILE="/var/log/photon/rebuild-cron.log"

log "Setting up cron job: '${CRON_EXPR} ${SCRIPT}'"

echo "${CRON_EXPR} root ${SCRIPT} >> ${LOGFILE} 2>&1" > /etc/cron.d/photon-rebuild
chmod 0644 /etc/cron.d/photon-rebuild
touch "$LOGFILE"
crontab /etc/cron.d/photon-rebuild

log "Cron job installed. Starting cron daemon..."
cron

tail -F "$LOGFILE"
