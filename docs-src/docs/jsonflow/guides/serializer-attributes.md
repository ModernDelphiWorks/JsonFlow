---
title: Serializer attributes
sidebar_position: 7
---

# Serializer attributes

JsonFlow ships custom RTTI attributes (unit `JsonFlow.Serializer.Attributes`) that control how properties are serialized and deserialized. Attributes are applied only when `TJSONSerializerOptions.ProcessAttributes` is `True` (the default).

## Available attributes

### `[JSONIgnore]`

Excludes a property entirely from serialization and deserialization.

```delphi
type
  TUser = class
  public
    Name: string;
    [JSONIgnore]
    InternalId: Integer; // not written to JSON, not read from JSON
  end;
```

### `[JSONName('key')]`

Maps a Delphi property to a different JSON key name.

```delphi
type
  TProduct = class
  public
    [JSONName('product_name')]
    Name: string;
    [JSONName('unit_price')]
    Price: Double;
  end;
```

Result: `{"product_name":"Widget","unit_price":9.99}`

### `[JSONInclude(AIncludeNull, AIncludeEmpty)]`

Controls whether null or empty values are written to the output.

```delphi
[JSONInclude(False, False)]
Description: string; // skipped when nil or empty
```

Default: both `True`.

### `[JSONDateTimeFormat('format')]` or `[JSONDateTimeFormat(AUseISO8601)]`

Overrides the DateTime serialization format for a specific property.

```delphi
[JSONDateTimeFormat(True)]        // ISO 8601 (e.g., "2026-06-20T12:00:00")
CreatedAt: TDateTime;

[JSONDateTimeFormat('dd/MM/yyyy')]
BirthDate: TDateTime;
```

### `[JSONFloatFormat(ADecimalPlaces, AUseDecimalSeparator?)]`

Overrides the float format for a specific property.

```delphi
[JSONFloatFormat(2)]         // 2 decimal places, use decimal separator (default True)
Price: Double;

[JSONFloatFormat(4, False)]  // 4 decimal places, no decimal separator
Rate: Double;
```

Constructor: `Create(const ADecimalPlaces: Integer; const AUseDecimalSeparator: Boolean = True)`

## Attribute inheritance

Attributes are read from the property definition on the class that declares it. Overriding a property in a subclass and re-applying a different attribute is supported.

## Enabling attribute processing

```delphi
var
  LOptions: TJSONSerializerOptions;
begin
  LOptions := TJSONSerializerOptions.Default;
  LOptions.ProcessAttributes := True; // already True by default
  LSerializer := TJSONSerializer.Create(LOptions);
end;
```

:::note
Attributes require `System.Rtti` in the uses clause of the unit where they are declared. Delphi automatically includes RTTI for published properties; for public properties, ensure RTTI generation is enabled (`{$RTTI EXPLICIT METHODS([]) FIELDS([]) PROPERTIES([vcPublic, vcPublished])}`).
:::
