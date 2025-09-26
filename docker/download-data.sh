#!/bin/bash
set -e

# Configuration
BASE_URL_WORLDWIDE="https://download1.graphhopper.com/public/experimental"
BASE_URL_EXTRACTS="https://download1.graphhopper.com/public/experimental/extracts"
DUMP_DIR="/photon/dumps"
MAX_RETRIES=3
RETRY_DELAY=5

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] DOWNLOAD: $1"
}

# Function to download file with retries
download_with_retry() {
    local url="$1"
    local output="$2"
    local retries=0
    
    while [ $retries -lt $MAX_RETRIES ]; do
        log "Downloading ${url} (attempt $((retries + 1))/${MAX_RETRIES})"
        
        if wget --progress=dot:giga -T 60 -t 1 "${url}" -O "${output}"; then
            log "Successfully downloaded ${output}"
            return 0
        else
            retries=$((retries + 1))
            if [ $retries -lt $MAX_RETRIES ]; then
                log "Download failed, retrying in ${RETRY_DELAY} seconds..."
                sleep $RETRY_DELAY
            fi
        fi
    done
    
    log "ERROR: Failed to download ${url} after ${MAX_RETRIES} attempts"
    return 1
}

# Function to get file size
get_file_size() {
    local url="$1"
    wget --spider --server-response "$url" 2>&1 | grep "Content-Length" | tail -1 | awk '{print $2}' || echo "0"
}

# Function to format bytes
format_bytes() {
    local bytes=$1
    if [ $bytes -gt 1073741824 ]; then
        echo "$(( bytes / 1073741824 ))GB"
    elif [ $bytes -gt 1048576 ]; then
        echo "$(( bytes / 1048576 ))MB"
    elif [ $bytes -gt 1024 ]; then
        echo "$(( bytes / 1024 ))KB"
    else
        echo "${bytes}B"
    fi
}

# Create dump directory
mkdir -p "${DUMP_DIR}"

# Parse countries argument
COUNTRIES="$1"

if [ -z "${COUNTRIES}" ]; then
    # Download world-wide data
    log "Downloading world-wide Photon data..."
    
    WORLD_URL="${BASE_URL_WORLDWIDE}/photon-db-latest.bz2"
    OUTPUT_FILE="${DUMP_DIR}/photon-db-latest.bz2"
    
    # Check if file exists and get size
    if wget --spider "${WORLD_URL}" 2>/dev/null; then
        file_size=$(get_file_size "${WORLD_URL}")
        log "World-wide database size: $(format_bytes $file_size)"
        
        download_with_retry "${WORLD_URL}" "${OUTPUT_FILE}"
        
        log "World-wide data download completed!"
        log "Downloaded file: ${OUTPUT_FILE}"
    else
        log "ERROR: World-wide database not available at ${WORLD_URL}"
        exit 1
    fi
else
    # Download country-specific data
    log "Downloading country-specific data for: ${COUNTRIES}"
    
    # Convert comma-separated countries to array
    IFS=',' read -ra COUNTRY_ARRAY <<< "${COUNTRIES}"
    
    # Create a temporary file for merging country data
    TEMP_MERGED="${DUMP_DIR}/merged.jsonl"
    > "${TEMP_MERGED}"  # Clear file
    
    downloaded_countries=()
    failed_countries=()
    
    for country in "${COUNTRY_ARRAY[@]}"; do
        # Trim whitespace
        country=$(echo "${country}" | tr -d ' ')
        country_lower=$(echo "${country}" | tr '[:upper:]' '[:lower:]')
        
        log "Processing country: ${country}"
        
        # Try different naming conventions for country files
        potential_files=(
            "${country_lower}.bz2"
            "${country}.bz2"
            "${country_lower}.jsonl.bz2"
            "${country}.jsonl.bz2"
        )
        
        downloaded=false
        for filename in "${potential_files[@]}"; do
            country_url="${BASE_URL_EXTRACTS}/${filename}"
            
            log "Checking ${country_url}..."
            if wget --spider "${country_url}" 2>/dev/null; then
                log "Found ${filename} for ${country}"
                
                file_size=$(get_file_size "${country_url}")
                log "File size: $(format_bytes $file_size)"
                
                temp_file="${DUMP_DIR}/${country}_${filename}"
                
                if download_with_retry "${country_url}" "${temp_file}"; then
                    # Extract and append to merged file
                    log "Extracting ${filename}..."
                    if [[ "${filename}" == *.bz2 ]]; then
                        bzip2 -dc "${temp_file}" >> "${TEMP_MERGED}"
                    else
                        cat "${temp_file}" >> "${TEMP_MERGED}"
                    fi
                    
                    # Clean up temporary file
                    rm -f "${temp_file}"
                    
                    downloaded_countries+=("${country}")
                    downloaded=true
                    break
                else
                    log "Failed to download ${filename}"
                    rm -f "${temp_file}"
                fi
            fi
        done
        
        if [ "$downloaded" = false ]; then
            log "WARNING: Could not find data for country: ${country}"
            failed_countries+=("${country}")
        fi
    done
    
    # Check if we downloaded any countries
    if [ ${#downloaded_countries[@]} -eq 0 ]; then
        log "ERROR: No country data could be downloaded!"
        rm -f "${TEMP_MERGED}"
        exit 1
    fi
    
    # Move merged file to final location
    mv "${TEMP_MERGED}" "${DUMP_DIR}/photon-db-latest.jsonl"
    
    log "Country-specific data download completed!"
    log "Successfully downloaded: ${downloaded_countries[*]}"
    if [ ${#failed_countries[@]} -gt 0 ]; then
        log "Failed to download: ${failed_countries[*]}"
    fi
    log "Merged data file: ${DUMP_DIR}/photon-db-latest.jsonl"
fi

# Show final file info
if [ -f "${DUMP_DIR}/photon-db-latest.bz2" ]; then
    size=$(stat -c%s "${DUMP_DIR}/photon-db-latest.bz2")
    log "Final compressed database size: $(format_bytes $size)"
elif [ -f "${DUMP_DIR}/photon-db-latest.jsonl" ]; then
    size=$(stat -c%s "${DUMP_DIR}/photon-db-latest.jsonl")
    log "Final JSONL database size: $(format_bytes $size)"
fi

log "Data download process completed successfully!"