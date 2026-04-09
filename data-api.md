# Data API

Machine-readable metadata, checksums, download URLs, and schemas are
available as static JSON files.

## Canonical GitHub Pages endpoints

| Endpoint | Description |
|----------|-------------|
| [`/data/index.json`](https://taehyun-lim.github.io/krpoltext/data/index.json) | Resource index (files, versions, SHA-256, download URLs) |
| [`/data/metadata.json`](https://taehyun-lim.github.io/krpoltext/data/metadata.json) | Dataset descriptions and citation info |
| [`/data/schema/campaign_booklet.json`](https://taehyun-lim.github.io/krpoltext/data/schema/campaign_booklet.json) | Column schema for campaign booklets |
| [`/data/schema/party_statements.json`](https://taehyun-lim.github.io/krpoltext/data/schema/party_statements.json) | Column schema for party statements |

## Raw GitHub fallback

If GitHub Pages is temporarily returning `404` for one of the JSON files,
the same published artifacts are mirrored on the `gh-pages` branch:

| Endpoint | Fallback URL |
|----------|--------------|
| `/data/index.json` | <https://raw.githubusercontent.com/taehyun-lim/krpoltext/gh-pages/data/index.json> |
| `/data/metadata.json` | <https://raw.githubusercontent.com/taehyun-lim/krpoltext/gh-pages/data/metadata.json> |
| `/data/schema/campaign_booklet.json` | <https://raw.githubusercontent.com/taehyun-lim/krpoltext/gh-pages/data/schema/campaign_booklet.json> |
| `/data/schema/party_statements.json` | <https://raw.githubusercontent.com/taehyun-lim/krpoltext/gh-pages/data/schema/party_statements.json> |

The GitHub Pages URLs remain the canonical public endpoints.
