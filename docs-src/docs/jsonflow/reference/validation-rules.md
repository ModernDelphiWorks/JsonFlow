---
title: Validation rules reference
sidebar_position: 3
---

# Validation rules reference

Each Draft 7 keyword is implemented as a separate rule class under `Source\Schema\Validators\`. This page lists every keyword and its implementation unit.

## Type keywords

| Keyword | Implementation unit |
|---|---|
| `type` | `JsonFlow.ValidationRules.Types` |
| `enum` | `JsonFlow.ValidationRules.Enum` |
| `const` | `JsonFlow.ValidationRules.Consts` |

## String keywords

| Keyword | Implementation unit |
|---|---|
| `minLength` | `JsonFlow.ValidationRules.MinLength` |
| `maxLength` | `JsonFlow.ValidationRules.MaxLength` |
| `pattern` | `JsonFlow.ValidationRules.Pattern` |
| `format` | `JsonFlow.ValidationRules.Format` |

## Number keywords

| Keyword | Implementation unit |
|---|---|
| `minimum` | `JsonFlow.ValidationRules.Minimum` |
| `maximum` | `JsonFlow.ValidationRules.Maximum` |
| `exclusiveMinimum` | `JsonFlow.ValidationRules.ExclusiveMinimum` |
| `exclusiveMaximum` | `JsonFlow.ValidationRules.ExclusiveMaximum` |
| `multipleOf` | `JsonFlow.ValidationRules.MultipleOf` |

## Array keywords

| Keyword | Implementation unit |
|---|---|
| `items` | `JsonFlow.ValidationRules.Items` |
| `minItems` | `JsonFlow.ValidationRules.MinItems` |
| `maxItems` | `JsonFlow.ValidationRules.MaxItems` |
| `uniqueItems` | `JsonFlow.ValidationRules.UniqueItems` |
| `contains` | `JsonFlow.ValidationRules.Contains` |

## Object keywords

| Keyword | Implementation unit |
|---|---|
| `properties` | `JsonFlow.ValidationRules.Properties` |
| `required` | `JsonFlow.ValidationRules.Required` |
| `additionalProperties` | `JsonFlow.ValidationRules.AdditionalProperties` |
| `patternProperties` | `JsonFlow.ValidationRules.PatternProperties` |
| `propertyNames` | `JsonFlow.ValidationRules.PropertyNames` |
| `minProperties` | `JsonFlow.ValidationRules.MinProperties` |
| `maxProperties` | `JsonFlow.ValidationRules.MaxProperties` |

## Composition keywords

| Keyword | Implementation unit |
|---|---|
| `allOf` | `JsonFlow.ValidationRules.AllOf` |
| `anyOf` | `JsonFlow.ValidationRules.AnyOf` |
| `oneOf` | `JsonFlow.ValidationRules.OneOf` |
| `not` | `JsonFlow.ValidationRules.NotRule` |
| `if` / `then` / `else` | `JsonFlow.ValidationRules.Conditional` |

## Reference

| Keyword | Implementation unit |
|---|---|
| `$ref` | `JsonFlow.ValidationRules.Ref` |

## Format validators

All format validators extend `TBaseFormatValidator` (unit `JsonFlow.FormatValidators.Base`). They are registered in `JsonFlow.FormatRegistry`.

| Format string | Class unit |
|---|---|
| `date` | `JsonFlow.FormatValidators.Date` |
| `date-time` | `JsonFlow.FormatValidators.DateTime` |
| `time` | `JsonFlow.FormatValidators.Time` |
| `email` | `JsonFlow.FormatValidators.Email` |
| `ipv4` | `JsonFlow.FormatValidators.Ipv4` |
| `ipv6` | `JsonFlow.FormatValidators.Ipv6` |
| `uri` | `JsonFlow.FormatValidators.Uri` |
| `uuid` | `JsonFlow.FormatValidators.Uuid` |
| `cpf` | `JsonFlow.FormatValidators.CPF` |
| `cnpj` | `JsonFlow.FormatValidators.CNPJ` |
| `cep` | `JsonFlow.FormatValidators.CEP` |
| `phone-br` | `JsonFlow.FormatValidators.BrazilianPhone` |
| `license-plate-br` | `JsonFlow.FormatValidators.BrazilianLicensePlate` |

## Base rule interfaces

Every validation rule must implement `IJSONSchemaTrait`:

```delphi
IJSONSchemaTrait = interface
  procedure Parse(const ANode: IJSONObject);   // extract keyword params from schema
  procedure SetNode(const ANode: TSchemaNode); // set owning schema node
  function Validate(const ANode: IJSONElement; const APath: String;
    var AErrors: TList<TValidationError>): Boolean;
end;
```

The abstract base `TBaseValidationRule` (unit `JsonFlow.ValidationRules.Base`) provides the common `AddError` helper and rule type classification (`TRuleType`):

| Value | Meaning |
|---|---|
| `rtPrimitive` | Validates a single keyword (e.g., `minLength`) |
| `rtComposite` | Combines multiple sub-schemas (e.g., `allOf`) |
| `rtStructural` | Structural constraint (e.g., `properties`) |

## Registering a custom format validator

```delphi
uses
  JsonFlow.FormatRegistry;

// Implement your validator
type
  TMyFormatValidator = class(TBaseFormatValidator)
    function Validate(const AValue: string): Boolean; override;
    function FormatName: string; override;
  end;

// Register at startup — RegisterValidator is a class method; Instance is available
// but registration goes directly through the class method:
TFormatRegistry.RegisterValidator('my-format', TMyFormatValidator.Create);
```

`TFormatRegistry.RegisterValidator` is a class (static) method — it does **not** require calling `.Instance` first. The registry dictionary is class-level. Other class methods: `UnregisterValidator`, `GetValidator`, `IsFormatRegistered`, `GetRegisteredFormats`, `ClearRegistry`.
