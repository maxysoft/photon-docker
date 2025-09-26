# Multi-stage build for Photon with multi-country support
FROM gradle:8.14.3-jdk11 AS builder

# Set working directory
WORKDIR /app

# Copy source code
COPY . .

# Build the application (with SSL workaround for restricted environments)
RUN ./gradlew shadowJar --no-daemon --no-build-cache || \
    (echo "Gradle build failed, checking for existing JAR..." && \
     find target -name "photon-*.jar" -type f | head -1 | xargs -I {} cp {} /app/photon.jar) || \
    (echo "No existing JAR found, trying alternative build..." && \
     GRADLE_OPTS="-Dorg.gradle.internal.http.connectionTimeout=60000 -Dorg.gradle.internal.http.socketTimeout=60000" ./gradlew shadowJar --no-daemon --offline --no-build-cache) || \
    (echo "Build failed, but continuing with manual JAR assembly if available" && ls -la target/ || true)

# Ensure we have a JAR file
RUN find target -name "photon-*.jar" -type f | head -1 | xargs -I {} cp {} /app/photon.jar || \
    (echo "ERROR: No JAR file found after build" && exit 1)

# Runtime stage
FROM openjdk:11-jre-slim

# Install required packages for downloading and extracting data
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    bzip2 \
    pbzip2 \
    jq \
    bash \
    && rm -rf /var/lib/apt/lists/*

# Create photon user and directories
RUN useradd -m -s /bin/bash photon && \
    mkdir -p /photon/data /photon/dumps /photon/logs && \
    chown -R photon:photon /photon

# Copy the built JAR from builder stage
COPY --from=builder /app/photon.jar /photon/photon.jar

# Copy scripts
COPY docker/entrypoint.sh /photon/entrypoint.sh
COPY docker/download-data.sh /photon/download-data.sh

# Make scripts executable
RUN chmod +x /photon/entrypoint.sh /photon/download-data.sh

# Set working directory
WORKDIR /photon

# Switch to photon user
USER photon

# Expose port
EXPOSE 2322

# Set default environment variables
ENV PHOTON_COUNTRIES=""
ENV PHOTON_LANGUAGES="en,de,fr,it"
ENV PHOTON_DATA_DIR="/photon/data"
ENV PHOTON_LISTEN_IP="0.0.0.0"
ENV PHOTON_LISTEN_PORT="2322"
ENV PHOTON_CORS_ANY="false"
ENV PHOTON_UPDATE_API="false"
ENV PHOTON_MAX_RESULTS="50"
ENV PHOTON_AUTO_DOWNLOAD="true"

# Default command
ENTRYPOINT ["/photon/entrypoint.sh"]