# Docker-based Multi-Country Photon Deployment (JSON Dump Composition)

This fork adds a production-oriented Docker setup to build a **single Photon index** from multiple public per-country Photon JSONL dumps (hosted by GraphHopper) without running a full Nominatim + PostgreSQL import pipeline.

## Key Differences vs Upstream (Original photon Repository)

| Aspect | Upstream (Typical) | This Fork Enhancement |
|--------|--------------------|-----------------------|
| Data acquisition | Pre-built `photon-db-...tar.bz2` or full Nominatim import | Composition of multiple country JSON dumps (`photon-dump-<country>-0.7-latest.jsonl.zst`) into one index |
| Nominatim dependency | Required for custom subsets not covered by dumps | Not required (we only use JSON dumps) |
| Multi-region subset | Usually one dump or full import with filters | Select arbitrary list of countries (e.g. JP,BG,HR,...) |
| Incremental updates | Possible via Nominatim replication | Not implemented (periodic full rebuild using latest dumps) |
| Rebuild strategy | Swap downloaded directories or re-import | Streaming (with retry) re-import from latest JSON dumps (atomic symlink swap) |
| Network resilience | Manual retry | Automatic per-dump retry & validation (configurable) |
| Disk usage control | Determined by dump or full import choice | You select which countries + retention controls |
| Advanced features (structured, geometry) | Supported if imported with flags | Limited to what dumps contain (public dumps do not include full geometry/structured extras) |

> IMPORTANT: This approach does **not** provide incremental OSM update latency. To refresh data, trigger a rebuild pulling the latest per-country JSON dumps.

---

## Architecture Overview

Services (see `docker-compose.yml`):

- **photon**: Runs Photon (embedded OpenSearch) from `/var/lib/photon/photon_data`.
- **nginx**: Public reverse proxy (domain placeholder: `photon.domain.com`) → Photon.
- **photon-rebuilder** (optional): Scheduled monthly rebuild via cron (or you can disable and use host cron). Has access to Docker socket to restart `photon` post rebuild.

### Data Directory Layout (Volume: `photon_data`)

```
/var/lib/photon/
  builds/
    build-20250926-203000/
      photon_data/...
  photon_data -> builds/build-20250926-203000/photon_data
  dumps/
    combined-20250926-203000.jsonl
  .current_build
```

Retention defaults:
- 1 build directory
- 1 combined JSON dump

---

## First Startup Flow

1. `entrypoint.sh` checks if `/var/lib/photon/photon_data` exists.
2. If absent or `FORCE_REIMPORT=1`:
   - Resolves URLs from `PHOTON_COUNTRIES`.
   - For each dump:
     - Downloads to a **temporary file** with retry logic and linear backoff.
     - Validates integrity via `zstd -t`.
     - (Checksum verification: MD5 sidecar or SHA256 expectation depending on mode.)
     - Streams decompressed JSON lines; temp file removed.
   - Optionally tees combined stream to `dumps/combined-<timestamp>.jsonl` (`PHOTON_KEEP_COMBINED_JSON=1`).
   - Imports via Photon `-import-file -` with languages.
   - Atomic symlink switch to new build directory.
3. Photon starts with configured run args.

Streaming ensures **no large RAM spike** beyond Java heap.

---

## Rebuilding (Manual)

```
FORCE_REIMPORT=1 PHOTON_COUNTRIES=JP,BG,HR,CZ,DE,GR,HU,IT,RO,RS,SI,SE \
  docker compose run --rm photon /opt/photon/scripts/rebuild_from_dumps.sh

docker compose restart photon
```

---

## Scheduled Monthly Rebuild (Optional)

If `photon-rebuilder` service is enabled (and Docker socket mounted):

Default cron: `0 3 1 * *` (03:00 UTC on day 1 monthly), executes:
```
/opt/photon/scripts/rebuild_from_dumps.sh --auto
```

Security note: Docker socket access = root-equivalent on host; enable only if trusted.

Host cron alternative example:
```
0 3 1 * * cd /path/to/project && FORCE_REIMPORT=1 docker compose run --rm photon /opt/photon/scripts/rebuild_from_dumps.sh && docker compose restart photon
```

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| PHOTON_VERSION | 0.7.4 | Photon release version (OpenSearch jar) |
| PHOTON_COUNTRIES | (required first run) | Comma-separated ISO codes mapped in `resolve_countries.sh` |
| PHOTON_DATA_DIR | /var/lib/photon | Data root |
| PHOTON_KEEP_COMBINED_JSON | 1 | Keep combined JSONL (subject to retention) |
| PHOTON_JAVA_OPTS | -Xms4g -Xmx8g | JVM memory |
| PHOTON_RUN_ARGS | -listen-ip 0.0.0.0 -cors-any -max-results 50 | Runtime flags |
| PHOTON_IMPORT_EXTRA_ARGS | (empty) | Additional importer flags |
| FORCE_REIMPORT | 0 | Force rebuild when set to 1 |
| RETENTION_BUILDS | 1 | Number of build dirs retained |
| RETENTION_DUMPS | 1 | Number of combined dumps retained |
| REBUILD_CRON | 0 3 1 * * | Cron expression (rebuilder) |
| PHOTON_SERVICE_LABEL | photon | Service label used for restart |
| DOWNLOAD_RETRIES | 5 | Per-dump retry attempts |
| DOWNLOAD_BACKOFF_SECONDS | 5 | Linear backoff base seconds |
| CHECKSUM_VERIFY | 1 | Enforce verification |
| CHECKSUM_RECORD | 1 | Record SHA256 for all files |
| CHECKSUM_ALGO | md5 | md5 | sha256 | auto |
| CHECKSUM_SOURCE_URL | (unset) | Remote SHA256 list (optional) |
| CHECKSUM_INLINE | (unset) | Inline SHA256 expectations |
| CHECKSUM_STRICT_FILENAMES | 0 | Fail if missing SHA256 expect (sha256 mode) |

---

## Checksum Verification

Integrity verification is enabled by default.

### Modes

| CHECKSUM_ALGO | Behavior |
|---------------|----------|
| md5 (default) | Use per-file `.md5` sidecar. Required when VERIFY=1; missing sidecar aborts. |
| sha256        | Use only SHA256 expectations (inline/remote). Missing expectation fails if VERIFY=1 (STRICT optional). |
| auto          | Try SHA256 expectation; if none, try MD5 sidecar; if neither and VERIFY=1 → fail. |

`CHECKSUM_RECORD=1` still records SHA256 of each downloaded file to a build-specific log for auditing.

Checksum log file: `dumps/checksums-<build_id>.txt`

---

## Health Check

`/status` endpoint polled by Docker healthcheck. Nginx proxies `/status` and `/health`.

---

## Quick Start

```
cp .env.example .env
# Edit PHOTON_COUNTRIES if needed

docker compose up --build -d
```

Test:
```
curl "http://localhost/api?q=berlin"
```

---

## Manual Rebuild

```
FORCE_REIMPORT=1 docker compose run --rm photon /opt/photon/scripts/rebuild_from_dumps.sh
Docker compose restart photon
```

---

## Troubleshooting

| Symptom | Cause | Resolution |
|---------|-------|-----------|
| Retry exhaustion | Network instability | Increase retries/backoff; rerun |
| Checksum mismatch | Corrupt or tampered dump | Retry; investigate source integrity |
| Empty results | Import failed | Check container logs and `.current_build` |
| Disk full | Retention or large dumps | Lower retention, prune old builds/dumps |

---

## Attribution

- OpenStreetMap data © [OpenStreetMap Contributors](https://www.openstreetmap.org/copyright) (ODbL)
- Per-country Photon dumps: hosted by [GraphHopper](https://www.graphhopper.com/)
- Photon (Apache 2.0) by Komoot
- OpenSearch project
- Geofabrik upstream regional extracts

---

## Disclaimer

This setup targets curated multi-country deployments with constrained disk and no near-real-time update requirement. For incremental updates adopt a full Nominatim + replication strategy.

Happy mapping!
