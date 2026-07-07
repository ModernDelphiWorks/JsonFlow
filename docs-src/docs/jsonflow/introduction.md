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

### 5. Audited performance

Every hot path was profiled and optimized in the July 2026 audit, validated with byte-identical output and reproducible console benchmarks:

| Hot path | Result |
|---|---|
| Serialization / deserialization | up to 26× faster than native Delphi `TJSON`; up to 15× faster than X-SuperObject |
| Schema validation | 3.4× faster (identity-based compile caching, precompiled regexes, O(1) error paths) |
| Path-based editing | up to 33× faster (`IJSONArray.Insert`, reusable navigation) |

## Compatibility

| Environment | Platform | Draft 7 | Custom Middlewares |
|---|---|:---:|:---:|
| Delphi XE or later | VCL, FMX, Console (Win/Linux/macOS/iOS/Android) | Yes | Yes |

:::note Platform status
Win32/Win64 is verified in production. All installed Delphi compilers build the full framework cleanly (verified 2026-07-07): Win32, Win64, Win64x (ARM64EC), Linux64, macOS Intel/ARM, iOS device/simulator.
:::
