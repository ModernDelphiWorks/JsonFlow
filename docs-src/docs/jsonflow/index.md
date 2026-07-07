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

Every hot path was profiled and optimized in the July 2026 audit (reproducible benchmarks): up to **26× faster** than native Delphi `TJSON`, up to **15× faster** than X-SuperObject, **3.4× faster** schema validation, and **33× faster** path-based editing.

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
| Custom middlewares | `IGetValueMiddleware` / `ISetValueMiddleware` |
| Horse middleware | `HorseJsonFlow` |

## Quick links

- [Installation](./getting-started/installation)
- [Quick start](./getting-started/quickstart)
- [Guides](./guides/serialize-object-to-json)
- [API reference](./reference/api)
