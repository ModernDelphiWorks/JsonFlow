# JSON Schema (Draft-07 pragmático)

Este documento descreve o estado atual do validador de JSON Schema no JsonFlow, com foco em:

- validação profunda (subschemas em qualquer nível)
- diagnósticos com `Path` e `SchemaPath`
- resolução de `$ref` (local e por arquivo), incluindo proteção contra circularidade

## Leitura e validação

`TJSONSchemaReader` é a forma mais simples de carregar um schema e validar JSON.

```pascal
uses
  System.SysUtils,
  JsonFlow.SchemaReader,
  JsonFlow.Interfaces;

var
  LReader: TJSONSchemaReader;
  LOk: Boolean;
  LErrors: TArray<TValidationError>;
begin
  LReader := TJSONSchemaReader.Create;
  try
    LReader.LoadFromString('{"type":"string","minLength":3}');
    LOk := LReader.Validate('"hi"');

    if not LOk then
    begin
      LErrors := LReader.GetErrors;
      Writeln(LErrors[0].Path);
      Writeln(LErrors[0].SchemaPath);
      Writeln(LErrors[0].Message);
    end;
  finally
    LReader.Free;
  end;
end.
```

## `Path` vs `SchemaPath`

- `Path`: onde no JSON de entrada ocorreu a falha (JSON Pointer, RFC6901)
- `SchemaPath`: onde no schema ocorreu a falha (também JSON Pointer)

Exemplo (falha em `minLength` dentro de `properties/a/properties/b`):

- `Path`: `/a/b`
- `SchemaPath`: `/properties/a/properties/b/minLength`

## `$ref` (local e por arquivo)

### `$ref` local com `$defs`

O compilador resolve referências locais no formato:

- `#/$defs/<Nome>`

Exemplo:

```json
{
  "$defs": {
    "ShortString": {"type":"string","minLength":3}
  },
  "properties": {
    "a": {"$ref":"#/$defs/ShortString"}
  }
}
```

### `$ref` por arquivo relativo (base URI)

Para referências como `defs.json#/$defs/Zip`, o base URI é determinado por `$id`.

Ao carregar com `LoadFromFile`, se o schema não tiver `$id`, o reader injeta um `$id` com o caminho do arquivo para permitir resolução relativa.

Exemplo:

- `root.json`

```json
{
  "type":"object",
  "properties": {
    "zip": {"$ref":"defs.json#/$defs/Zip"}
  },
  "required":["zip"]
}
```

- `defs.json`

```json
{
  "$defs": {
    "Zip": {"type":"string","minLength":8}
  }
}
```

## Circularidade em `$ref`

Referências circulares (ex.: `a.json -> b.json -> a.json`) são detectadas e não causam stack overflow.
O schema é compilado com uma regra de falha para indicar `$ref` não resolvido.

