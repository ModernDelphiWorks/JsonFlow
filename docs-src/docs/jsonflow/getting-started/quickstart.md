---
title: Quick start
sidebar_position: 2
---

# Quick start

Three core scenarios — each is self-contained.

## 1. Serialize a Delphi object to JSON

```delphi
uses
  JsonFlow,
  JsonFlow.Interfaces;

type
  TUser = class
  public
    Name: string;
    Age: Integer;
  end;

var
  LJson: string;
  LUser: TUser;
begin
  LUser := TUser.Create;
  try
    LUser.Name := 'John Doe';
    LUser.Age := 30;

    // Object → JSON string
    LJson := TJsonFlow.ObjectToJsonString(LUser);
    // Result: {"Name":"John Doe","Age":30}
  finally
    LUser.Free;
  end;
end;
```

## 2. Deserialize JSON back to an object

```delphi
uses
  JsonFlow;

var
  LJson: string;
  LUser: TUser;
begin
  LJson := '{"Name":"John Doe","Age":30}';

  // JSON string → typed object (caller owns the result)
  LUser := TJsonFlow.JsonToObject<TUser>(LJson);
  try
    WriteLn(LUser.Name); // John Doe
  finally
    LUser.Free;
  end;
end;
```

## 3. In-place dynamic JSON editing (TJSONComposer)

```delphi
uses
  JsonFlow.Composer,
  JsonFlow.Interfaces;

var
  LComposer: TJSONComposer;
  LInput, LResult: string;
begin
  LInput := '{"user":{"name":"John","age":30},"tags":["dev"]}';

  LComposer := TJSONComposer.Create;
  try
    LComposer.LoadJSON(LInput);
    LComposer.SetValue('user.age', 31);
    LComposer.AddToArray('tags', 'lead');
    LComposer.SetValue('user.email', 'john@email.com');

    LResult := LComposer.AsJSON;
    // {"user":{"name":"John","age":31,"email":"john@email.com"},"tags":["dev","lead"]}
  finally
    LComposer.Free;
  end;
end;
```

## 4. Draft 7 JSON Schema validation

```delphi
uses
  JsonFlow.SchemaValidator,
  JsonFlow.Reader,
  JsonFlow.Interfaces;

var
  LValidator: TSchemaValidator;
  LReader: TJSONReader;
  LSchema, LData: IJSONElement;
  LErrors: TArray<TValidationError>;
begin
  LReader := TJSONReader.Create;
  LValidator := TSchemaValidator.Create;
  try
    LSchema := LReader.Read(
      '{"type":"object","properties":{"name":{"type":"string","minLength":2}},"required":["name"]}'
    );
    LData := LReader.Read('{"name":"A"}'); // fails minLength

    LValidator.ParseSchema(LSchema);
    if not LValidator.Validate(LData) then
    begin
      LErrors := LValidator.GetErrors;
      WriteLn('Validation failed: ' + LErrors[0].Message);
      WriteLn('Path: ' + LErrors[0].Path);
    end;
  finally
    LValidator.Free;
    LReader.Free;
  end;
end;
```

## Next steps

- [Serialize objects to JSON](../guides/serialize-object-to-json) — options, attributes, lists.
- [Fluent writer](../guides/fluent-writer) — build JSON programmatically without strings.
- [Schema validation](../guides/schema-validation) — full Draft 7 keyword reference.
