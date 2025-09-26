#!/bin/bash
set -e

# Default values
PHOTON_JAR="/photon/photon.jar"
DATA_DIR="${PHOTON_DATA_DIR:-/photon/data}"
DUMP_DIR="/photon/dumps"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting Photon Docker container..."
log "Configuration:"
log "  Countries: ${PHOTON_COUNTRIES:-'all'}"
log "  Languages: ${PHOTON_LANGUAGES}"
log "  Data directory: ${DATA_DIR}"
log "  Listen IP: ${PHOTON_LISTEN_IP}"
log "  Listen port: ${PHOTON_LISTEN_PORT}"
log "  Auto-download: ${PHOTON_AUTO_DOWNLOAD}"

# Create necessary directories
mkdir -p "${DATA_DIR}" "${DUMP_DIR}"

# Check if data needs to be downloaded/imported
if [ "${PHOTON_AUTO_DOWNLOAD}" = "true" ] && [ ! -f "${DATA_DIR}/nodes" ]; then
    log "No existing data found, downloading and importing..."
    
    if [ -n "${PHOTON_COUNTRIES}" ]; then
        log "Downloading country-specific data for: ${PHOTON_COUNTRIES}"
        /photon/download-data.sh "${PHOTON_COUNTRIES}"
    else
        log "Downloading world-wide data..."
        /photon/download-data.sh
    fi
    
    # Import the downloaded data
    log "Importing data into Photon..."
    if [ -f "${DUMP_DIR}/photon-db-latest.bz2" ]; then
        log "Importing from compressed dump..."
        bzip2 -dc "${DUMP_DIR}/photon-db-latest.bz2" | java -jar "${PHOTON_JAR}" \
            -nominatim-import \
            -import-file - \
            -data-dir "${DATA_DIR}" \
            -languages "${PHOTON_LANGUAGES}"
    elif [ -f "${DUMP_DIR}/photon-db-latest.jsonl" ]; then
        log "Importing from JSONL dump..."
        java -jar "${PHOTON_JAR}" \
            -nominatim-import \
            -import-file "${DUMP_DIR}/photon-db-latest.jsonl" \
            -data-dir "${DATA_DIR}" \
            -languages "${PHOTON_LANGUAGES}"
    else
        log "ERROR: No dump file found for import!"
        exit 1
    fi
    
    log "Data import completed successfully!"
fi

# Build the Photon server command
JAVA_OPTS="${JAVA_OPTS:-}"
PHOTON_ARGS=""

# Add basic server arguments
PHOTON_ARGS="${PHOTON_ARGS} -data-dir ${DATA_DIR}"
PHOTON_ARGS="${PHOTON_ARGS} -listen-ip ${PHOTON_LISTEN_IP}"
PHOTON_ARGS="${PHOTON_ARGS} -listen-port ${PHOTON_LISTEN_PORT}"
PHOTON_ARGS="${PHOTON_ARGS} -languages ${PHOTON_LANGUAGES}"

# Add optional arguments
if [ "${PHOTON_CORS_ANY}" = "true" ]; then
    PHOTON_ARGS="${PHOTON_ARGS} -cors-any"
fi

if [ "${PHOTON_UPDATE_API}" = "true" ]; then
    PHOTON_ARGS="${PHOTON_ARGS} -enable-update-api"
fi

if [ -n "${PHOTON_MAX_RESULTS}" ]; then
    PHOTON_ARGS="${PHOTON_ARGS} -max-results ${PHOTON_MAX_RESULTS}"
fi

if [ -n "${PHOTON_SYNONYM_FILE}" ] && [ -f "${PHOTON_SYNONYM_FILE}" ]; then
    PHOTON_ARGS="${PHOTON_ARGS} -synonym-file ${PHOTON_SYNONYM_FILE}"
fi

if [ -n "${PHOTON_EXTRA_TAGS}" ]; then
    PHOTON_ARGS="${PHOTON_ARGS} -extra-tags ${PHOTON_EXTRA_TAGS}"
fi

# Handle custom arguments
if [ -n "${PHOTON_CUSTOM_ARGS}" ]; then
    PHOTON_ARGS="${PHOTON_ARGS} ${PHOTON_CUSTOM_ARGS}"
fi

log "Starting Photon server..."
log "Command: java ${JAVA_OPTS} -jar ${PHOTON_JAR} ${PHOTON_ARGS}"

# Start Photon server
exec java ${JAVA_OPTS} -jar "${PHOTON_JAR}" ${PHOTON_ARGS}