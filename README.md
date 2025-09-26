# About photon

[![Continuous Integration](https://github.com/komoot/photon/workflows/CI/badge.svg)](https://github.com/komoot/photon/actions)

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
