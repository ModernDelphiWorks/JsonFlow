---
title: Middleware pipeline
sidebar_position: 8
---

# Middleware pipeline

JsonFlow's middleware system lets you intercept property values during serialization (object→JSON) and deserialization (JSON→object). Implement `IGetValueMiddleware` to intercept reads (serialization) or `ISetValueMiddleware` to intercept writes (deserialization).

Both interfaces descend from `IEventMiddleware` (unit `JsonFlow.Interfaces`).

## IGetValueMiddleware — intercept during serialization

Called when serializing an object to JSON. Receive the property value and optionally override it (e.g., mask, encrypt, reformat).

```delphi
uses
  JsonFlow.Interfaces,
  System.Rtti;

type
  TMaskEmailMiddleware = class(TInterfacedObject, IEventMiddleware, IGetValueMiddleware)
  public
    procedure GetValue(const AInstance: TObject; const AProperty: TRttiProperty;
      var AValue: Variant; var ABreak: Boolean);
  end;

procedure TMaskEmailMiddleware.GetValue(const AInstance: TObject;
  const AProperty: TRttiProperty; var AValue: Variant; var ABreak: Boolean);
begin
  if AProperty.Name = 'Email' then
    AValue := '***@***.***'; // mask the value in JSON output
end;
```

## ISetValueMiddleware — intercept during deserialization

Called when populating a Delphi object from JSON. Receive the incoming value and optionally override it (e.g., decrypt, normalize).

```delphi
type
  TNormalizePhoneMiddleware = class(TInterfacedObject, IEventMiddleware, ISetValueMiddleware)
  public
    procedure SetValue(const AInstance: TObject; const AProperty: TRttiProperty;
      var AValue: Variant; var ABreak: Boolean);
  end;

procedure TNormalizePhoneMiddleware.SetValue(const AInstance: TObject;
  const AProperty: TRttiProperty; var AValue: Variant; var ABreak: Boolean);
begin
  if AProperty.Name = 'Phone' then
    AValue := RemoveNonDigits(VarToStr(AValue));
end;
```

## Registering middleware

### On TJsonFlow facade

```delphi
uses
  JsonFlow;

TJsonFlow.AddMiddleware(TMaskEmailMiddleware.Create);
```

The middleware is shared globally by the facade's internal builder.

### On TJSONSerializer instance

```delphi
uses
  JsonFlow.Serializer;

var
  LSerializer: TJSONSerializer;
begin
  LSerializer := TJSONSerializer.Create;
  LSerializer.Middlewares.Add(TMaskEmailMiddleware.Create);
end;
```

## The `ABreak` parameter

Set `ABreak := True` inside a middleware handler to prevent subsequent middlewares in the chain from running. The modified `AValue` is still applied.

## Date middleware

JsonFlow ships `TMiddlewareDateTime` (unit `JsonFlow.MiddlewareDatatime`) for handling custom date format conversions transparently.

:::tip
Use middleware for cross-cutting concerns — encryption, PII masking, format normalization — rather than implementing the same logic in each property or model class.
:::
