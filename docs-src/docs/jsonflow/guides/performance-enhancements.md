---
title: Performance enhancements
sidebar_position: 10
---

# Performance enhancements

JsonFlow ships three performance add-ons for high-throughput scenarios: **navigation caching**, **batch processing**, and **object pooling**. All are opt-in and can be combined.

## Navigation cache — TJSONComposerEnhanced

`TJSONComposerEnhanced` (unit `JsonFlow.Composer.Enhanced`) wraps any `IJSONComposer` and caches resolved JSON paths so that repeated traversals avoid re-walking the element tree.

**Reported speedup:** up to **2.5×** for repeated path lookups.

```delphi
uses
  JsonFlow.Composer,
  JsonFlow.Composer.Enhanced;

var
  LComposer: TJSONComposer;
  LEnhanced: TJSONComposerEnhanced;
begin
  LComposer := TJSONComposer.Create;
  LEnhanced := TJSONComposerEnhanced.Create(LComposer);
  try
    LComposer.LoadJSON(LLargeJson);

    // Configure cache
    var LConfig := TPerformanceConfig.Default;
    LConfig.Cache.Enabled := True;
    LConfig.Cache.MaxSize := 1000;
    LEnhanced.Configure(LConfig);

    // Enhanced SetValue goes through cache
    LEnhanced.SetValue('user.address.city', 'Berlin');
    LEnhanced.SetValue('user.address.zip', '10115');
    LEnhanced.SetValue('user.address.country', 'DE');

    // Stats
    WriteLn(LEnhanced.GetStatsReport);
  finally
    LEnhanced.Free;
    LComposer.Free;
  end;
end;
```

### TPerformanceConfig

```delphi
TPerformanceMode = (Default, HighPerformance, LowMemory, Balanced);

// Quick presets
LConfig := TPerformanceConfig.FromMode(TPerformanceMode.HighPerformance);
```

### TPerformanceStats

```delphi
LStats := LEnhanced.GetStats;
WriteLn('Hit rate: ' + FormatFloat('0.0%', LStats.HitRate));
WriteLn('Cache size: ' + IntToStr(LStats.CacheSize));
WriteLn('Total ops: ' + IntToStr(LStats.TotalOperations));
```

## Batch processing — BeginBatch / EndBatch

Batch mode defers the execution of multiple mutations and applies them in one pass, reducing redundant tree traversals.

**Reported speedup:** up to **3.4×** for bulk updates.

```delphi
LEnhanced.BeginBatch;
try
  LEnhanced.SetValue('order.status', 'shipped');
  LEnhanced.SetValue('order.shippedAt', Now);
  LEnhanced.AddToArray('order.events', 'status_changed');
  // ... many more operations ...
finally
  LEnhanced.EndBatch; // applies all at once
end;
```

Call `LEnhanced.ExecuteBatch` to apply without ending batch mode, or check `LEnhanced.IsBatchMode`.

### Bulk helpers

```delphi
// Set multiple key/value pairs in one call
LEnhanced.SetMultipleValues([
  'a.x', 1,
  'a.y', 2,
  'a.z', 3
]);

// Add multiple values to an array in one call
LEnhanced.AddMultipleToArray('items', [10, 20, 30]);
```

## Object pooling — TJSONComposerPool

`TJSONComposerPool` (unit `JsonFlow.Composer.Pool`) maintains a thread-safe pool of `TJSONComposer` instances. Borrow and return composers instead of creating/destroying them per request.

**Reported speedup:** up to **3×** faster in intensive creation/destruction loops.

```delphi
uses
  JsonFlow.Composer.Pool;

var
  LPool: TJSONComposerPool;
  LComposer: IJSONComposer;
begin
  LPool := TJSONComposerPool.Create;
  try
    LComposer := LPool.BorrowComposer;
    try
      LComposer.LoadJSON(LJson);
      LComposer.SetValue('status', 'ok');
      ProcessResult(LComposer.AsJSON);
    finally
      LPool.ReturnComposer(LComposer);
    end;

    WriteLn(LPool.GetStatsAsString);
  finally
    LPool.Free;
  end;
end;
```

### TPoolConfiguration

| Field | Type | Description |
|---|---|---|
| `MaxSize` | `Integer` | Maximum composers held in the pool |
| `PreAllocate` | `Integer` | Composers created eagerly at startup |
| `EnableStats` | `Boolean` | Track hit rate and borrow counts |

```delphi
var
  LConfig := TJSONComposerPool.TPoolConfiguration.Default;
LConfig.MaxSize := 20;
LPool.Configure(LConfig);
```

### TPooledJSONComposer — RAII helper

`TPooledJSONComposer` automatically returns the composer to the pool when it is freed:

```delphi
uses
  JsonFlow.Composer.Pool;

var
  LPooled: TPooledJSONComposer;
begin
  LPooled := TPooledJSONComposer.Create(LPool);
  try
    LPooled.Composer.LoadJSON(LJson);
    LPooled.Composer.SetValue('status', 'ok');
    ProcessResult(LPooled.Composer.AsJSON);
  finally
    LPooled.Free; // returns composer to pool automatically
  end;
end;
```

`TPooledJSONComposer` exposes the borrowed `IJSONComposer` via the `Composer` property (`property Composer: IJSONComposer read FComposer`). Destroying the wrapper calls `ReturnComposer` on the pool automatically.

## Choosing the right tier

| Scenario | Recommendation |
|---|---|
| Single ad-hoc JSON mutation | `TJSONComposer` directly |
| Repeated access to the same paths | `TJSONComposerEnhanced` with cache |
| Bulk update of many keys | `TJSONComposerEnhanced` with batch |
| High-concurrency server (many goroutines/threads) | `TJSONComposerPool` |
| All three at once | Pool + Enhanced + BeginBatch |
