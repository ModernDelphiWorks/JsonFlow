---
title: JsonFlow
sidebar_position: 1
displayed_sidebar: jsonflowSidebar
---

# JsonFlow

**JsonFlow** is a high-performance JSON serialization, dynamic manipulation, and Draft 7 Schema validation framework for Delphi.

[![Delphi XE+](https://img.shields.io/badge/Delphi-XE%20or%20superior-blue.svg)]()
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/ModernDelphiWorks/JsonFlow/blob/main/LICENSE)
[![CRA-ready](https://img.shields.io/badge/CRA--ready-SBOM%20%2B%20Security%20policy-success)](https://www.pubpascal.dev/packages/jsonflow)

## What is JsonFlow?

JsonFlow provides an enterprise-ready toolkit that integrates:

- **High-speed object serialization** — convert Delphi objects to/from JSON via RTTI, with custom attribute control.
- **In-place dynamic JSON editing** — load any JSON string and traverse or mutate it using dot-notation path strings (`user.address[0].zip`).
- **Full Draft 7 JSON Schema validation** — validate JSON structures against a schema with detailed local error paths (`Path` and `SchemaPath`).

Performance add-ons deliver up to **3.4× faster** bulk operations through navigation caching, batch processing, and thread-safe object pooling.

## Key features at a glance

| Feature | Class / Interface |
|---|---|
| Unified facade | `TJsonFlow` |
| Fluent JSON writer | `TJSONWriter` / `IJSONWriter` |
| JSON parser / reader | `TJSONReader` / `IJSONReader` |
| RTTI serializer | `TJSONSerializer` |
| In-place composer | `TJSONComposer` / `IJSONComposer` |
| Navigation helper | `TJSONNavigator` |
| Draft 7 validator | `TSchemaValidator` / `IJSONSchemaValidator` |
| Async validation | `TAsyncValidator` |
| Object pooling | `TJSONComposerPool` / `TPooledJSONComposer` |
| Performance add-ons | `TJSONComposerEnhanced` |
| Horse middleware | `HorseJsonFlow` |

## Quick links

- [Installation](./getting-started/installation)
- [Quick start](./getting-started/quickstart)
- [Guides](./guides/serialize-object-to-json)
- [API reference](./reference/api)
