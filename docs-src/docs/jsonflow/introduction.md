---
title: Introduction
sidebar_position: 2
---

# Introduction to JsonFlow

JsonFlow was created to solve the JSON problem in Object Pascal applications without compromise: speed, correctness, and ergonomics all at once.

## Design pillars

### 1. Unified facade — `TJsonFlow`

`TJsonFlow` is a class-based facade (no instance required) that groups the most common operations:

- `TJsonFlow.ObjectToJsonString(AObject)` — serialize any Delphi object to a JSON string.
- `TJsonFlow.JsonToObject<T>(AJson)` — deserialize a JSON string back to a typed object.
- `TJsonFlow.Write` — returns the shared `IJSONWriter` for building JSON programmatically.
- `TJsonFlow.Reader` — returns the shared `IJSONReader` for parsing JSON strings or streams.

### 2. Dual-layer architecture

JsonFlow has two layers:

| Layer | Purpose |
|---|---|
| **Core JSON layer** (`JsonFlow.Interfaces`, `JsonFlow.Value`, `JsonFlow.Objects`, `JsonFlow.Arrays`) | Low-level interface tree — `IJSONElement`, `IJSONObject`, `IJSONArray`, `IJSONValue` |
| **Feature layer** (`JsonFlow.Serializer`, `JsonFlow.Composer`, `JsonFlow.Schema.*`) | High-level features built on top of the core layer |

### 3. Interface-first

All JSON structures are accessed through interfaces (`IJSONElement`, `IJSONObject`, `IJSONArray`, etc.), which gives automatic lifetime management via reference counting in Delphi.

### 4. Middleware pipeline

Both serialization (read/write) and schema validation support a middleware pipeline. Implement `IGetValueMiddleware` or `ISetValueMiddleware` to intercept property values during serialization/deserialization (e.g., encrypt a field, reformat a date).

### 5. Performance tiers

| Tier | Mechanism | Speedup |
|---|---|---|
| Default | `TJSONComposer` | baseline |
| Navigation cache | `TJSONComposerEnhanced` with `EnableCache` | up to 2.5× |
| Batch mode | `BeginBatch` / `EndBatch` | up to 3.4× |
| Object pooling | `TJSONComposerPool` / `TPooledJSONComposer` | up to 3× |

## Compatibility

| Environment | Platform | Draft 7 | Pooling |
|---|---|:---:|:---:|
| Delphi XE or later | VCL, FMX, Console (Win/Linux/macOS/iOS/Android) | Yes | Yes |

:::note Linux64 status
Win32/Win64 is verified in production (2026-06-20). Linux64 consumer apps compile and run. A standalone full-framework Linux build has one tracked follow-up: `IEventMiddleware` is declared in both `JsonFlow.Types` and `JsonFlow.Interfaces` — choosing the canonical declaration resolves the ambiguity (this is not a platform issue).
:::
