---
title: Schema validation (Draft 7)
sidebar_position: 6
---

# Schema validation (Draft 7)

JsonFlow includes a full Draft 7 JSON Schema validator. The primary class is `TSchemaValidator` (unit `JsonFlow.SchemaValidator`), which implements `IJSONSchemaValidator`.

## Basic validation

```delphi
uses
  JsonFlow.SchemaValidator,
  JsonFlow.Reader,
  JsonFlow.Interfaces;

var
  LReader: TJSONReader;
  LValidator: TSchemaValidator;
  LSchema, LData: IJSONElement;
begin
  LReader := TJSONReader.Create;
  LValidator := TSchemaValidator.Create;
  try
    LSchema := LReader.Read(
      '{"type":"object",' +
      '"properties":{"name":{"type":"string","minLength":2}},' +
      '"required":["name"]}'
    );
    LData := LReader.Read('{"name":"A"}'); // will fail minLength

    LValidator.ParseSchema(LSchema);

    if not LValidator.Validate(LData) then
    begin
      for var LErr in LValidator.GetErrors do
        WriteLn(LErr.Path + ': ' + LErr.Message);
    end;
  finally
    LValidator.Free;
    LReader.Free;
  end;
end;
```

## Validate from strings

```delphi
// Both schema and data as strings
if not LValidator.Validate('{"name":"A"}', '{"type":"object","required":["name"]}') then
  WriteLn(LValidator.GetLastError);
```

## TValidationError fields

| Field | Type | Description |
|---|---|---|
| `Path` | `string` | JSON Pointer to the failing data location |
| `SchemaPath` | `string` | JSON Pointer to the failing schema keyword |
| `Message` | `string` | Human-readable error description |
| `FoundValue` | `string` | Actual value that failed |
| `ExpectedValue` | `string` | Expected value or constraint |
| `Keyword` | `string` | Schema keyword that triggered the error |
| `LineNumber` | `Integer` | Source line (when available) |
| `ColumnNumber` | `Integer` | Source column (when available) |
| `Context` | `string` | Additional context |

## Supported Draft 7 keywords

### Type validation
`type` — string, number, integer, boolean, null, array, object

### String keywords
`minLength`, `maxLength`, `pattern`, `format`

### Number keywords
`minimum`, `maximum`, `exclusiveMinimum`, `exclusiveMaximum`, `multipleOf`

### Array keywords
`items`, `minItems`, `maxItems`, `uniqueItems`, `contains`

### Object keywords
`properties`, `required`, `additionalProperties`, `patternProperties`, `propertyNames`, `minProperties`, `maxProperties`

### Composition keywords
`allOf`, `anyOf`, `oneOf`, `not`, `if` / `then` / `else`

### Reference
`$ref` — resolves internal (`#/definitions/...`) and external references

### Enumeration
`enum`

## Built-in format validators

JsonFlow ships format validators for:

| Format | Unit |
|---|---|
| `date` | `JsonFlow.FormatValidators.Date` |
| `date-time` | `JsonFlow.FormatValidators.DateTime` |
| `time` | `JsonFlow.FormatValidators.Time` |
| `email` | `JsonFlow.FormatValidators.Email` |
| `ipv4` | `JsonFlow.FormatValidators.Ipv4` |
| `ipv6` | `JsonFlow.FormatValidators.Ipv6` |
| `uri` | `JsonFlow.FormatValidators.Uri` |
| `uuid` | `JsonFlow.FormatValidators.Uuid` |
| `cpf` (Brazil) | `JsonFlow.FormatValidators.CPF` |
| `cnpj` (Brazil) | `JsonFlow.FormatValidators.CNPJ` |
| `cep` (Brazil) | `JsonFlow.FormatValidators.CEP` |
| `phone-br` (Brazil) | `JsonFlow.FormatValidators.BrazilianPhone` |
| `license-plate-br` | `JsonFlow.FormatValidators.BrazilianLicensePlate` |

## Loading schemas from files

Use `TJSONSchemaReader` (unit `JsonFlow.SchemaReader`) to load a schema from a file:

```delphi
uses
  JsonFlow.SchemaReader;

var
  LSchemaReader: TJSONSchemaReader;
begin
  LSchemaReader := TJSONSchemaReader.Create;
  try
    LSchemaReader.LoadFromFile('path/to/schema.json');
    // or: LSchemaReader.LoadFromString('{"type":"object",...}');

    if not LSchemaReader.Validate('{"name":"Alice"}') then
    begin
      for var LErr in LSchemaReader.GetErrors do
        WriteLn(LErr.Path + ': ' + LErr.Message);
    end;
  finally
    LSchemaReader.Free;
  end;
end;
```

`TJSONSchemaReader` public API:

| Member | Description |
|---|---|
| `Create` | Default constructor (uses Draft 7 validator internally) |
| `LoadFromFile(AFileName)` | Load and parse schema from a file; returns `Boolean` |
| `LoadFromString(AJsonString)` | Load and parse schema from a string; returns `Boolean` |
| `Validate(AJson)` | Validate JSON string against the loaded schema; returns `Boolean` |
| `Validate(AElement)` | Validate `IJSONElement` against the loaded schema; returns `Boolean` |
| `Validate(AJson, AJsonSchema)` | Validate JSON string with schema string in one call; returns `Boolean` |
| `GetErrors` | Returns `TArray<TValidationError>` |
| `GetVersion` | Returns the detected `TJsonSchemaVersion` |
| `GetSchema` | Returns the loaded schema as `IJSONElement` |

## External $ref resolution

Implement `IJSONSchemaRef` and register it with the validator to resolve external `$ref` URIs:

```delphi
uses
  JsonFlow.Interfaces;

type
  TMySchemaRef = class(TInterfacedObject, IJSONSchemaRef)
    function FetchReference(const ARef: string): IJSONElement;
  end;
```

Built-in HTTP resolvers are provided for Indy (`JsonFlow.SchemaRefIndy`) and Synapse (`JsonFlow.SchemaRefSynapse`).

## Logging

```delphi
LValidator.OnLog(
  procedure(const AMsg: string) begin WriteLn(AMsg); end
);
```

## Async validation

For validating large batches of documents in parallel, see [Async validation](./async-validation).
