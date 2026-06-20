---
title: Async validation
sidebar_position: 9
---

# Async validation

`TAsyncValidator` (unit `JsonFlow.AsyncValidator`) provides a multi-threaded, thread-safe background queue for validating large batches of JSON documents against a Draft 7 schema.

## Overview

- Validation tasks are submitted to a queue and executed in parallel worker threads.
- Each task has a configurable `TPriority` (Low, Normal, High, Critical).
- Completion and progress are reported via callbacks.

## Basic usage

```delphi
uses
  JsonFlow.AsyncValidator,
  JsonFlow.Interfaces,
  JsonFlow.Reader;

var
  LConfig: TAsyncValidator.TConfig;
  LValidator: TAsyncValidator;
  LReader: TJSONReader;
  LSchema: IJSONElement;
  LTaskId: string;
begin
  LConfig.MaxThreads := TThread.ProcessorCount; // default
  LConfig.QueueCapacity := 1000;               // default
  LConfig.TaskTimeoutSeconds := 300;           // default
  LConfig.EnablePrioritization := True;
  LConfig.EnableLoadBalancing := True;
  LConfig.ThreadIdleTimeoutSeconds := 60;      // default

  LReader := TJSONReader.Create;
  LSchema := LReader.Read('{"type":"object","required":["name"]}');
  LReader.Free;

  LValidator := TAsyncValidator.Create(LConfig);
  LValidator.Start;
  try
    // Submit a validation task — schema must be pre-parsed as IJSONElement
    LTaskId := LValidator.SubmitValidation(
      '{"name":"Alice"}',  // JSON data as string
      LSchema,             // schema as IJSONElement
      TAsyncValidator.TPriority.Normal
    );

    // Wait for all tasks (optional timeout in ms; -1 = infinite)
    LValidator.WaitForAllTasks(-1);
  finally
    LValidator.Free;
  end;
end;
```

## Task status

```delphi
TAsyncValidator.TStatus = (
  Queued,     // Task is waiting to be picked up by a worker thread
  Running,    // Task is currently being validated
  Completed,  // Validation finished (IsValid set accordingly)
  Cancelled,  // Task was cancelled before execution
  Error       // An exception occurred during validation
);
```

## TResult record

```delphi
TAsyncValidator.TResult = record
  TaskId: string;
  Status: TStatus;
  IsValid: Boolean;
  Errors: TList<TValidationError>;
  StartTime: TDateTime;
  EndTime: TDateTime;
  ErrorMessage: string;
end;
```

## Priority

```delphi
TAsyncValidator.TPriority = (
  Low,
  Normal,
  High,
  Critical
);
```

Higher-priority tasks are processed before lower-priority tasks in the queue when `EnablePrioritization` is `True` in `TConfig`.

## TConfig

| Field | Type | Default | Description |
|---|---|---|---|
| `MaxThreads` | `Integer` | `TThread.ProcessorCount` | Maximum parallel worker threads |
| `QueueCapacity` | `Integer` | `1000` | Maximum queued tasks |
| `TaskTimeoutSeconds` | `Integer` | `300` | Per-task timeout |
| `EnablePrioritization` | `Boolean` | `True` | Priority-queue ordering |
| `EnableLoadBalancing` | `Boolean` | `True` | Distribute load across threads |
| `ThreadIdleTimeoutSeconds` | `Integer` | `60` | Idle thread shutdown time |

## Callbacks

Completion and progress callbacks are passed per-call to `SubmitValidation` (or `SubmitBatchValidation`), not stored as properties on the validator. Both are `of object` method pointer types (`TCompletedCallback` / `TProgressCallback`), so they must be methods on an object instance.

```delphi
type
  TMyHandler = class
    procedure OnProgress(const ATaskId: string; AProgress, ATotal: Integer);
    procedure OnCompleted(const AResult: TAsyncValidator.TResult);
  end;

procedure TMyHandler.OnProgress(const ATaskId: string; AProgress, ATotal: Integer);
begin
  WriteLn(ATaskId + ': ' + IntToStr(AProgress) + '/' + IntToStr(ATotal));
end;

procedure TMyHandler.OnCompleted(const AResult: TAsyncValidator.TResult);
begin
  if AResult.IsValid then
    WriteLn(AResult.TaskId + ': valid')
  else
    WriteLn(AResult.TaskId + ': INVALID (' + IntToStr(AResult.Errors.Count) + ' errors)');
end;

// Submitting with callbacks:
var LHandler := TMyHandler.Create;
LTaskId := LValidator.SubmitValidation(
  LJsonData,
  LSchema,
  TAsyncValidator.TPriority.Normal,
  LHandler.OnProgress,   // TProgressCallback (ATaskId, AProgress, ATotal)
  LHandler.OnCompleted   // TCompletedCallback (AResult)
);
```

:::note
`TList<TValidationError>` in `TResult.Errors` is owned by the result. Callers must free it when done if they hold a reference to the result record outside the callback scope.
:::
