---
title: Deserialize JSON to object
sidebar_position: 2
---

# Deserialize JSON to object

JsonFlow uses RTTI to set public/published properties from a JSON object.

## Using the TJsonFlow facade

```delphi
uses
  JsonFlow;

// JSON string → new typed object (caller frees)
LUser := TJsonFlow.JsonToObject<TUser>(LJson);

// JSON string → existing object (in-place update; returns True on success)
TJsonFlow.JsonToObject(LJson, LExistingUser);

// JSON string → object list (generic)
LUserList := TJsonFlow.JsonToObjectList<TUser>(LJson);

// JSON string → object list (non-generic, type provided at runtime)
LList := TJsonFlow.JsonToObjectList(LJson, TUser);
```

## Using TJSONSerializer directly

```delphi
uses
  JsonFlow.Serializer,
  JsonFlow.Interfaces;

var
  LSerializer: TJSONSerializer;
begin
  LSerializer := TJSONSerializer.Create;
  try
    LSerializer.ToObject(LElement, LTargetObject);
  finally
    LSerializer.Free;
  end;
end;
```

`ToObject` populates `LTargetObject` from the `IJSONElement` and returns `True` on success.

## Property mapping rules

1. JSON keys are matched to Delphi property names case-insensitively by default.
2. Use `[JSONName('json_key')]` to override the mapping (see [Serializer attributes](./serializer-attributes)).
3. Use `[JSONIgnore]` to skip a property entirely.
4. Nested objects are recursively deserialized.
5. Dynamic arrays are deserialized from JSON arrays.

## Handling unknown keys

Unknown JSON keys (keys without a matching Delphi property) are silently skipped.

## Circular references

Enable detection via `TJSONSerializerOptions.DetectCircularReferences`. The `CircularReferenceStrategy` field controls behaviour:

The `TCircularReferenceStrategy` enum (unit `JsonFlow.Serializer.CircularRef`) has four values:

| Value | Behaviour |
|---|---|
| `crsException` | Raises `ECircularReferenceException` (default) |
| `crsNull` | Serializes the back-reference as JSON `null` |
| `crsReference` | Emits a `$ref` string pointing to the first occurrence |
| `crsIgnore` | Silently skips the back-reference property |

:::warning
The caller owns the object returned by `JsonToObject<T>`. Always wrap the result in a `try/finally` to avoid memory leaks.
:::
