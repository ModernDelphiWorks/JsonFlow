---
title: Installation
sidebar_position: 1
---

# Installation

## Via Boss (recommended)

[Boss](https://github.com/HashLoad/boss) is the de-facto package manager for Delphi. Install JsonFlow with one command:

```sh
boss install ModernDelphiWorks/JsonFlow
```

Boss downloads the sources into your project's `modules/` folder and adds the paths to your `.dproj` automatically.

## Via PubPascal

JsonFlow is registered on [PubPascal](https://www.pubpascal.dev/packages/jsonflow), the CRA-ready Pascal package portal. A machine-readable SBOM (CycloneDX) is published there for supply-chain transparency.

## Manual installation

1. Clone or download the repository: `https://github.com/ModernDelphiWorks/JsonFlow`
2. Add the following paths to your project's search path:

```
Source\
Source\Core\
Source\JSON\Core\
Source\JSON\Composition\
Source\JSON\IO\
Source\JSON\Middleware\
Source\Schema\Core\
Source\Schema\Composition\
Source\Schema\IO\
Source\Schema\Validators\
Source\Schema\Validators\Format\
Source\Schema\Validators\Format\Brazil\
Source\Addons\Composition\
Source\Addons\Validation\
```

3. To use the Horse middleware add `Source\Middleware-Horse\` to the search path and ensure [Horse](https://github.com/HashLoad/horse) is also on the path.

## Unit reference

| Unit | Purpose |
|---|---|
| `JsonFlow` | Unified `TJsonFlow` facade |
| `JsonFlow.Interfaces` | Core interface tree + schema interfaces |
| `JsonFlow.Writer` | `TJSONWriter` implementation |
| `JsonFlow.Reader` | `TJSONReader` implementation |
| `JsonFlow.Serializer` | RTTI-based `TJSONSerializer` |
| `JsonFlow.Serializer.Attributes` | Serialization control attributes |
| `JsonFlow.Composer` | `TJSONComposer` in-place editor |
| `JsonFlow.Navigator` | `TJSONNavigator` path helper |
| `JsonFlow.Composer.Enhanced` | `TJSONComposerEnhanced` (cache + batch) |
| `JsonFlow.Composer.Pool` | `TJSONComposerPool` / `TPooledJSONComposer` |
| `JsonFlow.SchemaValidator` | `TSchemaValidator` Draft 7 engine |
| `JsonFlow.AsyncValidator` | `TAsyncValidator` async queue |
| `Horse.JsonFlow` | Horse web-framework middleware |

## Requirements

- Delphi XE or later
- No external runtime dependencies for core functionality
- `Horse` required only for `Horse.JsonFlow` middleware
