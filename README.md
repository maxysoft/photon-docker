![Status: Experimental](https://img.shields.io/badge/Status-experimental-orange.svg)
![AI Assisted](https://img.shields.io/badge/AI-Generated-blueviolet)

> ### ⚠️ Important Disclaimer
> This codebase was assembled with significant help from AI tools and I'm not a software developer.  
> - Functionality may be incomplete or unstable.  
> - Security hardening and performance tuning have **not** been professionally audited.  
> - Breaking changes can happen at any time without notice.  
> - Do **not** rely on this in production environments without an expert review.
>
> Contributions, issue reports, and suggestions are welcome—but **use this repository at your own risk.**

# About photon

_photon_ is an open source geocoder built for
[OpenStreetMap](https://openstreetmap.org) data. It is based on
[elasticsearch](http://elasticsearch.org/)/[OpenSearch](https://opensearch.org/) -
an efficient, powerful and highly scalable search platform.

_photon_ was started by [komoot](http://www.komoot.de) who also provide the
public demo server at [photon.komoot.io](https://photon.komoot.io).

## NOTE: Docker Multi-Country JSON Deployment (Fork Enhancement)

This fork adds a production-oriented Docker setup to compose a **single Photon index** from multiple official public per‑country Photon JSONL dumps (no Nominatim required).  
See detailed guide:

➡ **[Docker Multi-Country Usage Guide](./README-Docker.md)**

Differences vs upstream:
- Composes multiple selected country JSON dumps (streamed with retry) into one index.
- No Nominatim import needed for custom multi-country subsets.
- Atomic symlink swap for rebuilds; optional scheduled monthly rebuild.
- Minimal retention (default 1 build / 1 dump) to fit tight disks.

```diff
+ Added: Docker multi-country JSON import workflow (see README-Docker.md)
+ Added: Robust retryable streamed importer scripts.
```

## Features

- high performance
- highly scalability
- search-as-you-type
- multilingual search
- location bias
- typo tolerance
- filter by osm tag and value
- filter by bounding box
- reverse geocode a coordinate to an address
- OSM data import (built upon [Nominatim](https://nominatim.org)) inclusive continuous updates
- import and export dumps in concatenated JSON format


## Import Performance

**Status:** Multi‑country Photon import completed successfully.

> VM Specs: 4vCPU AMD EPYC 7C13 / 16GB (photon limited to 8GB) / SSD with lvm and XFS fs

| Metric | Value |
|--------|-------|
| Countries | JP, BG, HR, CZ, DE, GR, HU, IT, RO, RS, SI, SE |
| Languages | en, de, fr, ja, it |
| Total Documents Imported | 49,803,430 |
| Total Processing Time | 13,066 s (~3h 37m 46s) |
| Average Throughput | ≈ 3,814 docs/sec |
| Peak Sample Rate (early phase snippet) | ~3,270 docs/sec (example) |
| Checksum Verification | All passed |
| Build ID | 20250926-223429 |
| Data Directory | /var/lib/photon/photon_data |
| Final Volume (Docker) | photon-docker_photon_data = 131.5 GB |
| Storage Type | Single-node (no replicas) |

<details>
<summary><strong>Raw Import Log Excerpt</strong></summary>

```text
[2025-09-26T22:35:30,824][INFO ][d.k.p.n.ImportThread     ] Imported 50000 documents [927.8331384883743/second]
...
[2025-09-26T23:12:23,316][INFO ][d.k.p.n.ImportThread     ] Imported 7400000 documents [3265.1159425021906/second]
...
[2025-09-26T23:17:22,706][INFO ][d.k.p.n.ImportThread     ] Imported 7500000 documents [2923.097969382303/second]
...
[2025-09-27T02:12:23,747][INFO ][d.k.p.n.ImportThread     ] Finished import of 49803430 photon documents. (Total processing time: 13066s)
[2025-09-27T02:12:23,749][INFO ][d.k.p.App                ] Database has been successfully set up with the following properties:
DatabaseProperties{languages=[en, de, fr, ja, it], importDate=Tue Sep 23 01:18:30 UTC 2025, supportStructuredQueries=false, supportGeometries=false}
...
[2025-09-27T02:12:28Z] Verifying photon_data directory creation.
[2025-09-27T02:14:45Z] Retention cleanup...
[2025-09-27T02:14:45Z] Pruning: /var/lib/photon/builds/build-20250926-222705
[2025-09-27T02:14:45Z] Pruning: /var/lib/photon/dumps/combined-20250926-222705.jsonl
[2025-09-27T02:14:45Z] Build 20250926-223429 complete.
[2025-09-27T02:14:45Z] All files passed checksum verification.
[2025-09-27T02:14:45Z] Launching Photon...
```
</details>

### Throughput Calculation

```
Average docs/sec = 49,803,430 documents / 13,066 s ≈ 3,814
```


## Known Limitations / FAQ

| Topic | Note |
|-------|------|
| Incremental updates | Full rebuild approach; no diff replication pipeline here. |
| Ranking | Not tuned—POIs can outrank administrative areas. |
| Security | No auth or rate limiting. Use proxy/WAF in public deployments. |
| Reverse geocode | Not a canonical address resolver; returns nearest feature. |
| Data freshness | Depends on dump cadence (using pre-built Photon dumps). |
| Multi-language anomalies | Some capital names return localized POIs or brand names due to token scoring. |
| JVM Warnings | Can silence with `--enable-native-access=ALL-UNNAMED --add-modules jdk.incubator.vector`. |

---

## Improvement Checklist

### Core Stability
- [ ] Permanently include `-data-dir /var/lib/photon` in runtime args
- [ ] Add empty-URL guard after resolving countries
- [ ] Add manifest of imported files + checksums
- [ ] Provide doc count + disk usage summary post-import

### Relevance / UX
- [ ] Post-filter to promote `place=city` for capital queries
- [ ] Optional param for admin-only results
- [ ] Add bounding bias examples

### Observability
- [ ] Prometheus metrics (optional sidecar)
- [ ] Diagnostics script (doc count, latency sample)

### Performance
- [ ] Document tuning of heap vs container memory
- [ ] Record per-country import durations
- [ ] Add latency benchmark script (p50/p95)

### Testing
- [ ] Shell script unit checks (shellcheck + integration)
- [ ] API smoke test in CI (`photon_validate.sh --json`)
- [ ] Retention logic test (create + prune builds)

### Security / Ops
- [ ] Add nginx rate limit template
- [ ] Disk space pre-check before starting import

### Docs
- [ ] Table of approximate disk usage per added country
- [ ] Troubleshooting section (common errors)

### Risk Mitigation
- [ ] Provide guidance for disk full scenarios (abort early).
- [ ] Add a guard for “java exits with non-zero” → mark build as failed clearly.
- [ ] Detect mismatch between PHOTON_VERSION env and jar version (parse jar manifest if available)

### Quality of Life Improvements
- [ ] Human-readable summary at end of import (rate per country, slowest file)
- [ ] Colorized logs (optional runtime flag)
- [ ] Add a “dry-run delete retention” preview mode

### Future Feature Ideas
- [ ] Add country-level toggle to skip already imported countries (partial rebuild strategy)
- [ ] Support incremental “append” if upstream starts providing diffs
- [ ] Provide a /metrics endpoint (if not using sidecar)
- [ ] Add simple clustering or bounding box filtering example (e.g., query param for restricting by lat/lon box)
- [ ] Multi-stage import (parallel download + pipeline decompress + import fifo)
- [ ] Pre-generate capital city synonyms file to improve ranking
