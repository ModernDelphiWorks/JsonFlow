---
title: Composer — dynamic editing
sidebar_position: 5
---

# Composer — dynamic editing

`TJSONComposer` (unit `JsonFlow.Composer`) provides an in-place, fluent API for building and mutating JSON structures. It implements `IJSONComposer`.

## Building JSON from scratch

```delphi
uses
  JsonFlow.Composer,
  JsonFlow.Interfaces;

var
  LComposer: TJSONComposer;
begin
  LComposer := TJSONComposer.Create;
  try
    LComposer
      .BeginObject
        .Add('name', 'Alice')
        .Add('age', 28)
        .Add('active', True)
        .BeginArray('tags')
          .Add('', 'dev')
          .Add('', 'lead')
        .EndArray
      .EndObject;

    WriteLn(LComposer.AsJSON);
  finally
    LComposer.Free;
  end;
end;
```

## Loading and mutating existing JSON

```delphi
LComposer := TJSONComposer.Create;
try
  LComposer.LoadJSON('{"user":{"name":"Bob","age":25},"tags":["dev"]}');

  // Dot-notation path for nested access
  LComposer.SetValue('user.age', 26);
  LComposer.AddToArray('tags', 'lead');
  LComposer.RemoveKey('user.name');

  WriteLn(LComposer.AsJSON);
finally
  LComposer.Free;
end;
```

## Array manipulation

```delphi
// Add single value
LComposer.AddToArray('items', 42);

// Add element (IJSONElement)
LComposer.AddToArray('items', LElement);

// Add multiple values
LComposer.AddToArray('items', TArray<Variant>.Create(1, 2, 3));

// Merge values into existing array
LComposer.MergeArray('items', TArray<Variant>.Create(4, 5));

// Remove by index
LComposer.RemoveFromArray('items', 0);

// Replace entire array content
LComposer.ReplaceArray('items', TArray<Variant>.Create(10, 20));
```

## Nested object manipulation

```delphi
// Add a named sub-object at path
LComposer.AddObject('user', 'address');

// Embed raw JSON at a key
LComposer.AddJSON('meta', '{"version":2}');
```

## Convenience value methods

```delphi
LComposer
  .StringValue('city', 'Berlin')
  .NumberValue('lat', 52.52)
  .IntegerValue('zoom', 14)
  .BooleanValue('visible', True)
  .NullValue('extra')
  .DateTimeValue('created', Now);
```

## Callback-style nested builders

```delphi
LComposer.ObjectValue('address',
  procedure(const B: IJSONComposer)
  begin
    B.Add('street', 'Main St')
     .Add('zip', '10115');
  end
);

LComposer.ArrayValue('scores',
  procedure(const B: IJSONComposer)
  begin
    B.Add('', 10).Add('', 20).Add('', 30);
  end
);
```

## Navigation and context

```delphi
// Navigate to a path for subsequent Add calls (context-aware)
LComposer.NavigateTo('user.address');
LComposer.GetCurrentPath; // returns 'user.address'
LComposer.GetContextInfo; // returns TContextInfo record
```

## Debug mode

```delphi
LComposer.EnableDebugMode(True);
// ... operations ...
for var LStep in LComposer.GetCompositionTrace do
  WriteLn(LStep);
```

## Output methods

| Method | Description |
|---|---|
| `AsJSON(AIdent)` | Returns compact or indented JSON string |
| `ToJSON(AIdent)` | Alias for `AsJSON` |
| `ToElement` | Returns the root `IJSONElement` |
| `GetRoot` | Returns the root `IJSONElement` |

## Merging

```delphi
// Merge another IJSONElement into the composer root
LComposer.Merge(LExtraElement);
```

## Cloning and clearing

```delphi
LClone := LComposer.Clone;   // deep copy
LComposer.Clear;             // reset to empty
```

## TJSONNavigator — read-only path access

For read-only navigation, use `TJSONNavigator` directly:

```delphi
uses
  JsonFlow.Navigator;

var
  LNav: TJSONNavigator;
begin
  LNav := TJSONNavigator.Create(LComposer.GetRoot);
  try
    WriteLn(LNav.GetString('user.name'));
    WriteLn(LNav.GetInteger('user.age'));
    WriteLn(BoolToStr(LNav.GetBoolean('active'), True));
    WriteLn(BoolToStr(LNav.IsNull('extra'), True));
  finally
    LNav.Free;
  end;
end;
```

`TJSONNavigator` supports dot-notation and array index notation (`tags[0]`).

