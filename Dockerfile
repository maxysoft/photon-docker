# Multi-country Photon Docker Image (JSON dump composition with verification)
# Build: docker build --build-arg PHOTON_VERSION=0.7.4 -t photon-multicountry:latest .

FROM eclipse-temurin:21-jre AS runtime

ARG PHOTON_VERSION=0.7.4
ENV PHOTON_VERSION=${PHOTON_VERSION}

# Packages:
# - coreutils provides md5sum
# - keep bash explicitly (entrypoint & scripts use bash)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    zstd \
    ca-certificates \
    bash \
    coreutils \
    cron \
    jq \
    procps \
    findutils \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/photon

RUN set -eux; \
    curl -L -o photon-opensearch-${PHOTON_VERSION}.jar \
      https://github.com/komoot/photon/releases/download/${PHOTON_VERSION}/photon-opensearch-${PHOTON_VERSION}.jar; \
    test -s photon-opensearch-${PHOTON_VERSION}.jar

RUN ln -s photon-opensearch-${PHOTON_VERSION}.jar photon.jar

RUN mkdir -p /var/lib/photon /opt/photon/scripts /var/log/photon

ENV PHOTON_DATA_DIR=/var/lib/photon \
    PHOTON_JAVA_OPTS="-Xms4g -Xmx8g" \
    PHOTON_RUN_ARGS="-data-dir /var/lib/photon -listen-ip 0.0.0.0 -cors-any -max-results 50" \
    PHOTON_IMPORT_EXTRA_ARGS="" \
    PHOTON_COUNTRIES="" \
    PHOTON_KEEP_COMBINED_JSON=1 \
    FORCE_REIMPORT=0 \
    RETENTION_BUILDS=1 \
    RETENTION_DUMPS=1 \
    PHOTON_SERVICE_LABEL=photon \
    REBUILD_CRON="0 3 1 * *" \
    DOWNLOAD_RETRIES=5 \
    DOWNLOAD_BACKOFF_SECONDS=5 \
    CHECKSUM_VERIFY=1 \
    CHECKSUM_RECORD=1 \
    CHECKSUM_ALGO=md5 \
    CHECKSUM_STRICT_FILENAMES=0

COPY scripts/ /opt/photon/scripts/
RUN chmod +x /opt/photon/scripts/*.sh

ENTRYPOINT ["/opt/photon/scripts/entrypoint.sh"]
CMD ["java","-jar","/opt/photon/photon.jar"]
