---
title: API reference
sidebar_position: 1
---

# API reference

## TJsonFlow (unit `JsonFlow`)

Static class facade. No instance required.

### Serialization methods

| Method | Description |
|---|---|
| `ObjectToJsonString(AObject, AStoreClassName?)` | Serialize object to JSON string |
| `ObjectListToJsonString(AObjectList, AStoreClassName?)` | Serialize `TObjectList<TObject>` to JSON array string |
| `ObjectListToJsonString<T>(AObjectList, AStoreClassName?)` | Generic variant for `TObjectList<T>` |
| `JsonToObject<T>(AJson)` | Deserialize JSON string to new typed object (caller frees) |
| `JsonToObject<T>(AObject, AJson)` | Populate existing object in-place; returns `Boolean` |
| `JsonToObject(AJson, AObject)` | Populate existing `TObject` in-place |
| `JsonToObjectList<T>(AJson)` | Deserialize JSON array to `TObjectList<T>` (caller frees) |
| `JsonToObjectList(AJson, AType)` | Non-generic variant; takes `TClass` at runtime |

### Writer / reader accessors

| Method | Description |
|---|---|
| `Write` | Returns the shared `IJSONWriter` |
| `Reader` | Returns the shared `IJSONReader` |
| `BeginObject(AValue?)` | Shortcut to `FJsonWriter.BeginObject` |
| `BeginArray` | Shortcut to `FJsonWriter.BeginArray` |
| `ParseFromFile(AFileName, AUtf8?)` | Parse JSON from file into shared reader |
| `SaveJsonToFile(AFileName, AUtf8?)` | Save reader's last parsed element to file |

### Middleware and settings

| Method / Property | Description |
|---|---|
| `AddMiddleware(AEventMiddleware)` | Register a middleware on the shared builder |
| `FormatSettings` (read/write) | Global `TFormatSettings` for writer/reader/builder |
| `OnSetValue` (deprecated) | Use middlewares instead |
| `OnGetValue` (deprecated) | Use middlewares instead |

---

## TJSONWriter (unit `JsonFlow.Writer`)

| Member | Description |
|---|---|
| `Create` | Default en-US format settings |
| `Create(AFormatSettings)` | Custom format settings |
| `Write(AElement, AIdent?)` | Returns compact or indented JSON string |
| `WriteToStream(AElement, AStream, AIdent?)` | UTF-8 encode to stream |
| `OnLog(ALogProc)` | Register log callback |

---

## TJSONReader (unit `JsonFlow.Reader`)

| Member | Description |
|---|---|
| `Create` | Default settings, 64 KB buffer |
| `Create(ABufferSize)` | Custom buffer size (min 4 KB) |
| `Create(AFormatSettings)` | Custom format settings |
| `Create(AFormatSettings, ABufferSize)` | Both custom |
| `Read(AJson)` | Parse JSON string → `IJSONElement` |
| `ReadFromStream(AStream)` | Parse from stream → `IJSONElement` |
| `OnLog(ALogProc)` | Register log callback |
| `OnProgress(AProgress)` | Register progress callback (stream only) |
| `BufferSize` | Read/write buffer size property |

---

## TJSONSerializer (unit `JsonFlow.Serializer`)

| Member | Description |
|---|---|
| `Create` | Default settings |
| `Create(AFormatSettings, AUseISO8601?)` | Custom format / ISO 8601 flag |
| `Create(AOptions)` | Full `TJSONSerializerOptions` record |
| `FromObject(AObject, AStoreClassName?)` | Object → `IJSONElement` |
| `ToObject(AElement, AObject)` | `IJSONElement` → populates existing object; returns `Boolean` |
| `OnLog(ALogProc)` | Register log callback |
| `Middlewares` | `TList<IEventMiddleware>` — register get/set middlewares |
| `Options` | Read/write `TJSONSerializerOptions` |

---

## TJSONComposer (unit `JsonFlow.Composer`)

All builder methods return `IJSONComposer` for chaining.

### Construction
`Create` — empty composer.

### Building JSON
`BeginObject(AName?)`, `EndObject`, `BeginArray(AName?)`, `EndArray`

### Adding values
`Add(AName, AValue)` — overloaded for `String`, `Integer`, `Double`, `Boolean`, `TDateTime`, `IJSONElement`, `Char`, `Variant`, and typed arrays (`TArray<Integer>`, `TArray<String>`, etc.)

`AddNull(AName)`, `AddArray(AName, AValues[])`, `AddJSON(AName, AJson)`

### Convenience value methods
`StringValue`, `NumberValue`, `IntegerValue`, `BooleanValue`, `NullValue`, `DateTimeValue`

### Callback-style nested builders
`ObjectValue(AName, ACallback)`, `ArrayValue(AName, ACallback)`

### Loading and manipulation
`LoadJSON(AJson)`, `SetValue(APath, AValue)`, `RemoveKey(APath)`, `Merge(AElement)`

### Array manipulation
`AddToArray(APath, AValue)`, `MergeArray(APath, AValues)`, `RemoveFromArray(APath, AIndex)`, `ReplaceArray(APath, AValues)`, `AddObject(APath, AName)`

### Navigation
`NavigateTo(APath)`, `GetCurrentPath`, `GetContextInfo`

### Output
`AsJSON(AIdent?)`, `ToJSON(AIdent?)`, `ToElement`, `GetRoot`

### Utilities
`Clone`, `Clear`, `ForEach(ACallback)`, `OnLog(ALogProc)`, `EnableDebugMode(AEnabled)`, `GetCompositionTrace`

### Validation helpers
`QuickValidate`, `ValidateStructure`, `IsValidJSON`, `GetValidationErrors`, `EnableRealTimeValidation(AEnabled)`

### Performance
`GetPerformanceMetrics`, `OptimizeMemory`, `EnableLazyLoading(AEnabled)`, `Benchmark(AOperation)`

---

## TJSONNavigator (unit `JsonFlow.Navigator`)

| Member | Description |
|---|---|
| `Create(ARoot)` | Wrap an `IJSONElement` root |
| `GetValue(APath)` | Any element at path → `IJSONElement` |
| `GetObject(APath)` | `IJSONObject` at path |
| `GetArray(APath)` | `IJSONArray` at path |
| `GetString(APath)` | String value at path |
| `GetInteger(APath)` | `Int64` value at path |
| `GetFloat(APath)` | `Double` value at path |
| `GetBoolean(APath)` | `Boolean` value at path |
| `IsNull(APath)` | Returns `True` if value is null or missing |
| `Root` | Read-only property returning the root element |

Path syntax: dot-notation (`user.address.city`) and array indices (`items[0].name`).

---

## TJSONComposerEnhanced (unit `JsonFlow.Composer.Enhanced`)

Wraps `IJSONComposer` and adds caching and batching.

| Member | Description |
|---|---|
| `Create(AComposer)` | Wrap any `IJSONComposer` |
| `Configure(AConfig)` | Apply `TPerformanceConfig` |
| `SetPerformanceMode(AMode)` | Quick preset (Default/HighPerformance/LowMemory/Balanced) |
| `ClearCache` | Invalidate path cache |
| `BeginBatch`, `EndBatch`, `ExecuteBatch` | Batch control |
| `IsBatchMode` | Returns `True` if in batch mode |
| `SetValue(APath, AValue)` | Cache-aware mutation; returns `Boolean` |
| `AddToArray(APath, AValue)` | Cache-aware array append; returns `Boolean` |
| `RemoveKey(APath)` | Cache-aware key removal; returns `Boolean` |
| `SetMultipleValues(APathValuePairs)` | Bulk key/value update |
| `AddMultipleToArray(APath, AValues)` | Bulk array append |
| `GetStats` | Returns `TPerformanceStats` |
| `GetStatsReport` | Returns stats as formatted string |
| `ResetStats` | Zero counters |

---

## TJSONComposerPool (unit `JsonFlow.Composer.Pool`)

| Member | Description |
|---|---|
| `Create(ACreateFunc?)` | Optional custom factory for composers |
| `BorrowComposer` | Get a composer from the pool (creates if needed) |
| `ReturnComposer(AComposer)` | Return a composer to the pool |
| `GetStats` | Returns `TPoolStats` |
| `GetStatsAsString` | Returns stats as formatted string |
| `Clear` | Drain pool (frees all pooled composers) |
| `Configure(AConfig)` | Apply `TPoolConfiguration` |

---

## TSchemaValidator (unit `JsonFlow.SchemaValidator`)

Implements `IJSONSchemaValidator`.

| Member | Description |
|---|---|
| `ParseSchema(ASchema)` | Load schema from `IJSONElement` |
| `Validate(AJson, AJsonSchema?)` | Validate JSON string (optionally with schema string) |
| `Validate(AElement, APath?)` | Validate `IJSONElement` |
| `GetErrors` | Returns `TArray<TValidationError>` |
| `GetVersion` | Returns detected schema version (`TJsonSchemaVersion`) |
| `GetLastError` | Returns last error message as string |
| `AddLog(AMessage)` | Append to internal log |
| `OnLog(ALogProc)` | Register log callback |

---

## TAsyncValidator (unit `JsonFlow.AsyncValidator`)

See [Async validation](../guides/async-validation) for the full guide.

| Member | Description |
|---|---|
| `Create(AConfig)` | Requires explicit `TConfig` record |
| `Start` / `Stop` / `Pause` / `Resume` | Lifecycle control |
| `SubmitValidation(AJsonData, ASchema, APriority?, AProgressCallback?, ACompletedCallback?)` | Submit one task; returns `TaskId: string` |
| `SubmitBatchValidation(AJsonDataList, ASchema, APriority?, ...)` | Submit multiple tasks; returns `TArray<string>` of task IDs |
| `CancelTask(ATaskId)` | Cancel a queued/running task; returns `Boolean` |
| `GetTaskStatus(ATaskId)` | Returns `TStatus` |
| `GetTaskResult(ATaskId)` | Returns `TResult`; raises if not completed |
| `WaitForTask(ATaskId, ATimeoutMs?)` | Block until task done; returns `Boolean` |
| `WaitForAllTasks(ATimeoutMs?)` | Block until queue is empty; returns `Boolean` |
| `GetStats` | Returns `TStats` record |
| `GetQueueSize` | Returns `Integer` |
| `GetActiveThreadCount` | Returns `Integer` |
| `Config` | Read/write `TConfig` property |

Callbacks (`TProgressCallback`, `TCompletedCallback`) are passed per-call to `SubmitValidation`, not stored as properties on the validator instance.
