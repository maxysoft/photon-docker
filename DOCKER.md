# Photon Docker Multi-Country Deployment

This Docker implementation provides comprehensive support for deploying Photon with multi-country configurations, allowing you to run country-specific geocoding services or world-wide instances.

## Features

- **Multi-country support**: Deploy separate instances for different countries or regions
- **Automatic data download**: Automatically downloads and imports official Photon JSONL dumps
- **Flexible configuration**: Environment-based configuration for easy customization
- **Health checks**: Built-in health monitoring for all services
- **Load balancing**: Optional nginx reverse proxy for distributing requests
- **Resource optimization**: Configurable memory and performance settings
- **Volume management**: Persistent data storage with Docker volumes

## Quick Start

### Simple Single-Country Deployment

For a quick start with a single country (e.g., Germany):

```bash
# Clone the repository
git clone <repository-url>
cd photon-docker

# Start with Germany data
docker-compose -f docker-compose.simple.yml up -d

# The service will be available at http://localhost:2322
```

### Multi-Country Deployment

For a complete multi-country setup:

```bash
# Start all services (this will take time to download and import data)
docker-compose up -d

# Services will be available at:
# - World-wide: http://localhost:2322
# - Europe: http://localhost:2323
# - North America: http://localhost:2324
# - Germany: http://localhost:2325
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PHOTON_COUNTRIES` | `""` | Comma-separated country codes (ISO 3166-1 alpha-2). Empty = world-wide |
| `PHOTON_LANGUAGES` | `"en,de,fr,it"` | Comma-separated language codes |
| `PHOTON_DATA_DIR` | `"/photon/data"` | Directory for Photon database files |
| `PHOTON_LISTEN_IP` | `"0.0.0.0"` | IP address to bind to |
| `PHOTON_LISTEN_PORT` | `"2322"` | Port to listen on |
| `PHOTON_CORS_ANY` | `"false"` | Enable CORS for any origin |
| `PHOTON_UPDATE_API` | `"false"` | Enable update API endpoint |
| `PHOTON_MAX_RESULTS` | `"50"` | Maximum number of search results |
| `PHOTON_AUTO_DOWNLOAD` | `"true"` | Automatically download data if not present |
| `PHOTON_SYNONYM_FILE` | `""` | Path to synonym file |
| `PHOTON_EXTRA_TAGS` | `""` | Extra OSM tags to include |
| `PHOTON_CUSTOM_ARGS` | `""` | Additional command line arguments |
| `JAVA_OPTS` | `""` | JVM options (e.g., `-Xmx4g`) |

### Country Codes

Use ISO 3166-1 alpha-2 country codes. Examples:

- **Single country**: `PHOTON_COUNTRIES=de`
- **Multiple countries**: `PHOTON_COUNTRIES=de,fr,it,es`
- **Region examples**:
  - Europe: `de,fr,it,es,nl,be,at,ch,pl,cz`
  - North America: `us,ca,mx`
  - Nordic: `se,no,dk,fi`

### Memory Requirements

Recommended memory settings based on data size:

- **Single small country** (e.g., Netherlands): `-Xmx1g`
- **Single large country** (e.g., Germany, France): `-Xmx2g`
- **Multiple countries**: `-Xmx3g-4g`
- **World-wide**: `-Xmx8g+` (requires significant memory)

## Docker Compose Examples

### Custom Country Configuration

Create your own `docker-compose.override.yml`:

```yaml
version: '3.8'

services:
  photon-custom:
    build: .
    container_name: photon-custom
    ports:
      - "2326:2322"
    environment:
      - PHOTON_COUNTRIES=se,no,dk,fi  # Nordic countries
      - PHOTON_LANGUAGES=sv,no,da,fi,en
      - PHOTON_CORS_ANY=true
      - JAVA_OPTS=-Xmx2g
    volumes:
      - photon-custom-data:/photon/data
      - photon-custom-dumps:/photon/dumps
    restart: unless-stopped

volumes:
  photon-custom-data:
  photon-custom-dumps:
```

### Production Configuration

For production deployments:

```yaml
version: '3.8'

services:
  photon-prod:
    build: .
    container_name: photon-prod
    ports:
      - "2322:2322"
    environment:
      - PHOTON_COUNTRIES=de,fr,it,es,nl,be,at,ch
      - PHOTON_LANGUAGES=de,fr,it,es,nl,en
      - PHOTON_CORS_ANY=false
      - PHOTON_UPDATE_API=true
      - PHOTON_MAX_RESULTS=25
      - JAVA_OPTS=-Xmx6g -XX:+UseG1GC -XX:MaxGCPauseMillis=200
    volumes:
      - /opt/photon/data:/photon/data
      - /opt/photon/dumps:/photon/dumps
      - /opt/photon/logs:/photon/logs
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-size: "100m"
        max-file: "5"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:2322/status"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 300s
```

## Data Management

### Data Sources

The Docker implementation automatically downloads data from official Photon sources:
- World-wide: `https://download1.graphhopper.com/public/experimental/`
- Country extracts: `https://download1.graphhopper.com/public/experimental/extracts/`

### Manual Data Import

To use your own data files:

1. Disable auto-download: `PHOTON_AUTO_DOWNLOAD=false`
2. Mount your data files to `/photon/dumps/`
3. Name your file `photon-db-latest.bz2` or `photon-db-latest.jsonl`

```yaml
services:
  photon:
    # ... other configuration
    environment:
      - PHOTON_AUTO_DOWNLOAD=false
    volumes:
      - ./my-data.bz2:/photon/dumps/photon-db-latest.bz2:ro
      - photon-data:/photon/data
```

### Data Updates

For production environments with update capability:

```bash
# Enable update API
PHOTON_UPDATE_API=true

# Trigger updates via API
curl http://localhost:2322/nominatim-update

# Check update status
curl http://localhost:2322/nominatim-update/status
```

## Networking and Load Balancing

### With Nginx Proxy

To use the included nginx load balancer:

```bash
docker-compose --profile with-proxy up -d
```

This provides:
- Default world-wide service on port 80
- Region-specific routing based on hostname
- CORS headers
- Health check endpoints

### Custom Load Balancing

For custom load balancing, you can:

1. Use external load balancers (HAProxy, Traefik, etc.)
2. Route based on query parameters
3. Implement geographic routing

## Monitoring and Logging

### Health Checks

All services include health checks via `/status` endpoint:

```bash
# Check service health
curl http://localhost:2322/status

# Docker health status
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### Logs

Access container logs:

```bash
# View logs
docker-compose logs photon-germany

# Follow logs
docker-compose logs -f photon-europe

# View all logs
docker-compose logs
```

### Monitoring with External Tools

Example with Prometheus monitoring:

```yaml
services:
  photon:
    # ... existing configuration
    labels:
      - "prometheus.scrape=true"
      - "prometheus.port=2322"
      - "prometheus.path=/status"
```

## Troubleshooting

### Common Issues

1. **Out of Memory**
   ```bash
   # Increase JVM heap size
   JAVA_OPTS=-Xmx4g
   ```

2. **Slow Download/Import**
   ```bash
   # Check download progress
   docker-compose logs -f photon-germany
   
   # Monitor disk space
   docker system df
   ```

3. **Port Conflicts**
   ```bash
   # Change port mapping
   ports:
     - "2323:2322"  # Use different host port
   ```

4. **Data Corruption**
   ```bash
   # Remove data and restart
   docker-compose down
   docker volume rm photon-docker_photon-data
   docker-compose up -d
   ```

### Performance Tuning

1. **JVM Tuning**:
   ```
   JAVA_OPTS=-Xmx4g -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+DisableExplicitGC
   ```

2. **Disk I/O**:
   - Use SSD storage for volumes
   - Consider dedicated volume drivers

3. **Network**:
   - Use host networking for better performance
   - Adjust nginx worker processes

## Security Considerations

1. **CORS Configuration**:
   - Set `PHOTON_CORS_ANY=false` in production
   - Configure specific origins if needed

2. **Update API**:
   - Only enable `PHOTON_UPDATE_API=true` if needed
   - Protect with reverse proxy authentication

3. **Resource Limits**:
   ```yaml
   services:
     photon:
       deploy:
         resources:
           limits:
             cpus: '2.0'
             memory: 4G
           reservations:
             memory: 2G
   ```

4. **Network Security**:
   - Use internal networks for service communication
   - Expose only necessary ports

## Examples and Use Cases

### 1. Regional Service Provider

Deploy separate instances for different regions:

```yaml
services:
  photon-eu:
    # European countries
    environment:
      - PHOTON_COUNTRIES=de,fr,it,es,nl,be,at,ch,pl,cz,hu,sk,si,hr,bg,ro,ee,lv,lt
      
  photon-na:
    # North American countries
    environment:
      - PHOTON_COUNTRIES=us,ca,mx
      
  photon-asia:
    # Asian countries
    environment:
      - PHOTON_COUNTRIES=jp,kr,cn,in,th,sg,my,id,ph,vn
```

### 2. Language-Specific Services

Deploy instances optimized for specific languages:

```yaml
services:
  photon-german:
    environment:
      - PHOTON_COUNTRIES=de,at,ch
      - PHOTON_LANGUAGES=de,en
      
  photon-french:
    environment:
      - PHOTON_COUNTRIES=fr,be,ch,ca
      - PHOTON_LANGUAGES=fr,en
```

### 3. Development Environment

Quick setup for development:

```yaml
services:
  photon-dev:
    build: .
    ports:
      - "2322:2322"
    environment:
      - PHOTON_COUNTRIES=de  # Small dataset for testing
      - PHOTON_CORS_ANY=true
      - JAVA_OPTS=-Xmx1g
    volumes:
      - photon-dev-data:/photon/data
```

This Docker implementation provides a complete solution for multi-country Photon deployments with automatic data management, flexible configuration, and production-ready features.