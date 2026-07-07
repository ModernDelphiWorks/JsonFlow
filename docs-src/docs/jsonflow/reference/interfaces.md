---
title: Interfaces
sidebar_position: 2
---

# Interfaces (unit `JsonFlow.Interfaces`)

All JSON structures in JsonFlow are accessed through interfaces, enabling automatic reference-counted lifetime management.

## Core element hierarchy

```
IJSONElement
├── IJSONValue      (scalar: string, number, bool, null, datetime)
├── IJSONObject     (key/value map: "{}")
└── IJSONArray      (ordered list: "[]")
```

## IJSONElement

```delphi
IJSONElement = interface
  function AsJSON(const AIdent: Boolean = False): String;
  procedure SaveToStream(AStream: TStream; const AIdent: Boolean = False);
  function Clone: IJSONElement;
  function TypeName: string;   // 'object', 'array', 'string', 'integer', 'float', 'boolean', 'null', 'datetime'
end;
```

## IJSONValue

```delphi
IJSONValue = interface(IJSONElement)
  function IsString: Boolean;
  function IsInteger: Boolean;
  function IsFloat: Boolean;
  function IsBoolean: Boolean;
  function IsNull: Boolean;
  function IsDate: Boolean;
  property AsBoolean: Boolean;
  property AsInteger: Int64;
  property AsFloat: Double;
  property AsString: String;
end;
```

## IJSONObject

```delphi
IJSONObject = interface(IJSONElement)
  function Add(const AKey: String; const AValue: IJSONElement): IJSONPair;
  function GetValue(const AKey: String): IJSONElement;
  function ContainsKey(const AKey: String): Boolean;
  function Count: Integer;
  procedure Remove(const AKey: String);
  procedure Clear;
  procedure ForEach(const ACallback: TProc<String, IJSONElement>);
  function Filter(const APredicate: TFunc<String, IJSONElement, Boolean>): IJSONObject;
  function Map(const ATransform: TFunc<String, IJSONElement, IJSONPair>): IJSONObject;
  function Pairs: TArray<IJSONPair>;
end;
```

## IJSONArray

```delphi
IJSONArray = interface(IJSONElement)
  procedure Add(const AValue: IJSONElement);
  function GetItem(const AIndex: Integer): IJSONElement;
  function Count: Integer;
  procedure Remove(const AIndex: Integer);
  procedure Clear;
  procedure ForEach(const ACallback: TProc<IJSONElement>);
  function Filter(const APredicate: TFunc<IJSONElement, Boolean>): IJSONArray;
  function Map(const ATransform: TFunc<IJSONElement, IJSONElement>): IJSONArray;
  function Items: TArray<IJSONElement>;
  function Value(AIndex: Integer): IJSONElement;
end;
```

## IJSONPair

```delphi
IJSONPair = interface
  property Key: String;
  property Value: IJSONElement;
  function AsJSON(const AIdent: Boolean = False): String;
end;
```

## IJSONWriter

```delphi
IJSONWriter = interface
  function Write(const AElement: IJSONElement; const AIdent: Boolean = False): String;
  procedure WriteToStream(const AElement: IJSONElement; AStream: TStream; const AIdent: Boolean = False);
  procedure OnLog(const ALogProc: TProc<String>);
end;
```

## IJSONReader

```delphi
IJSONReader = interface
  function Read(const AJson: String): IJSONElement;
  function ReadFromStream(AStream: TStream): IJSONElement;
  procedure OnLog(const ALogProc: TProc<String>);
  procedure OnProgress(const AProgress: TProc<TObject, Single>);
end;
```

## Middleware interfaces

```delphi
IEventMiddleware = interface
  // base marker interface
end;

IGetValueMiddleware = interface(IEventMiddleware)
  procedure GetValue(const AInstance: TObject; const AProperty: TRttiProperty;
    var AValue: Variant; var ABreak: Boolean);
end;

ISetValueMiddleware = interface(IEventMiddleware)
  procedure SetValue(const AInstance: TObject; const AProperty: TRttiProperty;
    var AValue: Variant; var ABreak: Boolean);
end;
```

## Schema interfaces

```delphi
IJSONSchemaValidator = interface
  function Validate(const AJson: string; const AJsonSchema: string = ''): Boolean; overload;
  function Validate(const AElement: IJSONElement; const APath: string = ''): Boolean; overload;
  procedure ParseSchema(const ASchema: IJSONElement);
  function GetErrors: TArray<TValidationError>;
  function GetVersion: TJsonSchemaVersion;
  function GetLastError: string;
  procedure OnLog(const ALogProc: TProc<String>);
  // Additional: AddLog, AddError
end;

IJSONSchemaRef = interface
  function FetchReference(const ARef: string): IJSONElement;
end;

IJSONSchemaReader = interface
  function LoadFromFile(const AFileName: string): Boolean;
  function LoadFromString(const AJsonString: string): Boolean;
  function Validate(const AJson: string): Boolean; overload;
  function Validate(const AElement: IJSONElement): Boolean; overload;
  function GetErrors: TArray<TValidationError>;
  function GetVersion: TJsonSchemaVersion;
  function GetSchema: IJSONElement;
end;
```

## Composer interface

`IJSONComposer` is the full fluent interface for `TJSONComposer`. See the [API reference](./api) for the complete member list.

## Validation types

```delphi
TValidationError = record
  Path: string;           // JSON Pointer to failing data location
  SchemaPath: string;     // JSON Pointer to failing schema keyword
  Message: string;
  FoundValue: string;
  ExpectedValue: string;
  Keyword: string;
  LineNumber: Integer;
  ColumnNumber: Integer;
  Context: string;
  function ToString: string;
end;

TValidationResult = record
  IsValid: Boolean;
  Errors: TArray<TValidationError>;
  Path: string;
  ExecutionTime: Int64;
  CacheHit: Boolean;

  class function Success(const APath: string = ''): TValidationResult; static;
  class function Failure(const APath: string; const AErrors: TArray<TValidationError>): TValidationResult; static;
end;

TJsonSchemaVersion = (
  jsvUnknown, jsvDraft3, jsvDraft4, jsvDraft6,
  jsvDraft7, jsvDraft201909, jsvDraft202012
);
```
