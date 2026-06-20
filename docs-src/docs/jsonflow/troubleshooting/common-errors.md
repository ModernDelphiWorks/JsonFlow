---
title: Common errors
sidebar_position: 1
---

# Common errors and troubleshooting

## Parse errors

### `EJsonFlowParseError: Empty JSON string`

**Cause:** `TJSONReader.Read('')` was called.

**Fix:** Guard the call:

```delphi
if LJson <> '' then
  LRoot := LReader.Read(LJson);
```

---

### `EJsonFlowParseError: Unexpected end of JSON`

**Cause:** The input JSON is truncated (e.g., only part of a response was received from a network socket).

**Fix:** Ensure the full response body is accumulated before parsing. For streaming scenarios, use `TJSONReader.ReadFromStream` with a complete stream.

---

### `EJsonFlowParseError: Extra characters after JSON`

**Cause:** Valid JSON followed by trailing characters (e.g., a BOM, whitespace, or a second JSON document concatenated without separation).

**Fix:** Strip trailing whitespace/BOM from the input before parsing, or split compound streams at document boundaries.

---

### `EJsonFlowParseError: Invalid escape sequence`

**Cause:** A `\x` escape inside a JSON string that is not one of the six valid escapes (`\"`, `\\`, `\/`, `\b`, `\f`, `\n`, `\r`, `\t`, `\uXXXX`).

**Fix:** Ensure the source system produces valid JSON. Use a JSON validator (e.g., `jsonlint.com`) to identify the bad string.

---

## Serialization errors

### Property not appearing in JSON output

**Possible causes:**

1. The property is `[JSONIgnore]` decorated.
2. The property is private (RTTI does not expose private members by default).
3. `IgnoreNullValues: True` in `TJSONSerializerOptions` and the property value is null/default.

**Fix:**
- Make the property `public` or `published`.
- Remove `[JSONIgnore]` if present.
- Set `IgnoreNullValues := False` if null values must be included.

---

### Wrong JSON key name in output

**Cause:** A `[JSONName('key')]` attribute is applied to the property, overriding the Delphi property name.

**Fix:** Check the property declaration for `[JSONName]` attributes.

---

### Circular reference exception

**Cause:** An object graph contains a cycle (A → B → A).

**Fix:** Enable detection in options:

```delphi
LOptions.DetectCircularReferences := True;
LOptions.CircularReferenceStrategy := crsException; // crsException | crsNull | crsReference | crsIgnore
```

---

## Schema validation issues

### Validation always returns `True` when no schema is loaded

**Cause:** `ParseSchema` was not called before `Validate`.

**Fix:**

```delphi
LValidator.ParseSchema(LSchema);  // required before Validate
if not LValidator.Validate(LData) then ...
```

---

### `$ref` not resolved — validation skips `$ref` keywords

**Cause:** External `$ref` URIs require a registered `IJSONSchemaRef` resolver. Without one, external references are skipped or raise an error.

**Fix:** Register a ref resolver (Indy or Synapse built-ins):

```delphi
uses
  JsonFlow.SchemaRefIndy; // or JsonFlow.SchemaRefSynapse

// The concrete resolver classes (TJSONSchemaRefIndy / TJSONSchemaRefSynapse) implement
// IJSONSchemaRef.FetchReference. No public registration API is exposed on
// TJSONSchemaValidator / IJSONSchemaValidator in the current release — external
// $ref resolution is handled internally by the schema compiler's HTTP resolution
// path (TSchemaCompiler.EnableHTTPResolution). Consult the framework release notes
// for the intended external-ref registration surface.
```

---

### Brazilian format validators not triggering

**Cause:** Brazil-specific formats (`cpf`, `cnpj`, `cep`, `phone-br`, `license-plate-br`) are in separate units that must be included in the project's search path and explicitly referenced (or their units pulled in).

**Fix:** Add `Source\Schema\Validators\Format\Brazil\` to the project search path and `uses` one of the Brazil validator units, or call the registry registration code at startup.

---

## Performance issues

### High memory usage with many concurrent requests

**Cause:** Each request creates and destroys a `TJSONComposer`, triggering repeated allocation.

**Fix:** Use `TJSONComposerPool`:

```delphi
LComposer := LPool.BorrowComposer;
try
  // use composer
finally
  LPool.ReturnComposer(LComposer);
end;
```

---

### Repeated path lookups are slow

**Cause:** `TJSONComposer` re-walks the element tree for every path-based operation.

**Fix:** Wrap with `TJSONComposerEnhanced` and enable the path cache:

```delphi
var LCfg := TPerformanceConfig.Default;
LCfg.Cache.Enabled := True;
LEnhanced.Configure(LCfg);
```

---

## Linux64 build issues

### Ambiguous `IEventMiddleware` symbol

**Cause:** `IEventMiddleware` is declared in both `JsonFlow.Types` and `JsonFlow.Interfaces`. Including both in the same `uses` clause creates an ambiguity.

**Fix:** Use the canonical declaration from `JsonFlow.Interfaces` only. Remove `JsonFlow.Types` from the `uses` clause where the conflict occurs, or qualify the identifier: `JsonFlow.Interfaces.IEventMiddleware`.

This is a tracked framework issue (not a platform issue) — a future release will remove the duplicate declaration.
