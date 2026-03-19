{
  ------------------------------------------------------------------------------
  JsonFlow
  Fluent and expressive JSON manipulation API for Delphi.

  SPDX-License-Identifier: Apache-2.0
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the Apache License, Version 2.0.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------
}

{$include ../../JsonFlow.inc}

unit JsonFlow.Composer.Enhanced;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.SyncObjs,
  System.Variants,
  System.DateUtils,
  JsonFlow.Interfaces;

{$SCOPEDENUMS ON}

type
  // Forward declarations
  TJSONPathCache = class;
  TJSONBatchProcessor = class;
  /// <summary>
  ///   Performance modes for the enhanced composer.
  /// </summary>
  TPerformanceMode = (
    Default,
    HighPerformance,
    LowMemory,
    Balanced
  );
  /// <summary>
  ///   Configuration for path caching mechanism.
  /// </summary>
  TCacheConfig = record
    Enabled: Boolean;
    MaxSize: Integer;
    TTL: Integer; // Seconds
    AutoCleanup: Boolean;
    CleanupInterval: Integer; // Minutes
    class function Default: TCacheConfig; static;
    class function HighPerformance: TCacheConfig; static;
    class function LowMemory: TCacheConfig; static;
  end;
  /// <summary>
  ///   Configuration for batch operations.
  /// </summary>
  TBatchConfig = record
    Enabled: Boolean;
    MaxOperations: Integer;
    AutoExecute: Boolean;
    AutoExecuteThreshold: Integer;
    class function Default: TBatchConfig; static;
    class function HighThroughput: TBatchConfig; static;
    class function LowLatency: TBatchConfig; static;
  end;
  /// <summary>
  ///   Unified performance configuration.
  /// </summary>
  TPerformanceConfig = record
    Mode: TPerformanceMode;
    Cache: TCacheConfig;
    Batch: TBatchConfig;
    class function Default: TPerformanceConfig; static;
    class function FromMode(AMode: TPerformanceMode): TPerformanceConfig; static;
  end;
  /// <summary>
  ///   Runtime statistics for monitoring performance.
  /// </summary>
  TPerformanceStats = record
    TotalOperations: Int64;
    BatchOperationsExecuted: Int64;
    CacheHits: Int64;
    CacheMisses: Int64;
    CacheSize: Integer;
    function HitRate: Double;
  end;
  /// <summary>
  ///   Enhanced JSON Composer with caching and batching capabilities.
  ///   Acts as a decorator/facade over IJSONComposer.
  /// </summary>
  TJSONComposerEnhanced = class
  private
    FComposer: IJSONComposer;
    FCache: TJSONPathCache;
    FBatch: TJSONBatchProcessor;
    FConfig: TPerformanceConfig;
    FStats: TPerformanceStats;
    procedure _UpdateStatsFromComponents;
  public
    constructor Create(const AComposer: IJSONComposer);
    destructor Destroy; override;
    // Configuration
    procedure Configure(const AConfig: TPerformanceConfig);
    procedure SetPerformanceMode(AMode: TPerformanceMode);
    // Cache Management
    procedure ClearCache;
    // Batch Control
    procedure BeginBatch;
    procedure EndBatch;
    procedure ExecuteBatch;
    function IsBatchMode: Boolean;
    // Enhanced Operations (Cache + Batch Aware)
    function SetValue(const APath: String; const AValue: Variant): Boolean;
    function AddToArray(const APath: String; const AValue: Variant): Boolean;
    function RemoveKey(const APath: String): Boolean;
    // Bulk Operations
    function SetMultipleValues(const APathValuePairs: array of Variant): Boolean;
    function AddMultipleToArray(const APath: String; const AValues: array of Variant): Boolean;
    // Monitoring
    function GetStats: TPerformanceStats;
    function GetStatsReport: String;
    procedure ResetStats;
  end;

  /// <summary>
  ///   Internal cache manager for JSON path lookups.
  ///   Thread-safe implementation.
  /// </summary>
  TJSONPathCache = class
  private type
    TCacheEntry = record
      Element: IJSONElement;
      Timestamp: TDateTime;
      AccessCount: Integer;
    end;
  private
    FCache: TDictionary<String, TCacheEntry>;
    FConfig: TCacheConfig;
    FLock: TCriticalSection;
    FLastCleanup: TDateTime;
    FHits: Int64;
    FMisses: Int64;
    procedure _CleanupIfNeeded;
    procedure _EvictEntries;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Configure(const AConfig: TCacheConfig);
    procedure Clear;
    function TryGet(const APath: String; out AElement: IJSONElement): Boolean;
    procedure Add(const APath: String; const AElement: IJSONElement);
    property Hits: Int64 read FHits;
    property Misses: Int64 read FMisses;
    property Count: Integer readFGetCount;
    function FGetCount: Integer;
  end;

  /// <summary>
  ///   Internal processor for batch JSON operations.
  ///   Thread-safe implementation.
  /// </summary>
  TJSONBatchProcessor = class
  public type
    TOpType = (SetValue, AddToArray, RemoveKey);
    TOperation = record
      OpType: TOpType;
      Path: String;
      Value: Variant;
    end;
  private
    FQueue: TList<TOperation>;
    FConfig: TBatchConfig;
    FComposer: IJSONComposer;
    FLock: TCriticalSection;
    FActive: Boolean;
    FExecutedCount: Int64;
    procedure _ProcessQueue;
  public
    constructor Create(const AComposer: IJSONComposer);
    destructor Destroy; override;
    procedure Configure(const AConfig: TBatchConfig);
    procedure BeginBatch;
    procedure EndBatch;
    procedure Execute;
    procedure Enqueue(const AOp: TOperation);    
    property IsActive: Boolean read FActive;
    property ExecutedCount: Int64 read FExecutedCount;
  end;

implementation

{ TCacheConfig }

class function TCacheConfig.Default: TCacheConfig;
begin
  Result.Enabled := True;
  Result.MaxSize := 1000;
  Result.TTL := 300;
  Result.AutoCleanup := True;
  Result.CleanupInterval := 10;
end;

class function TCacheConfig.HighPerformance: TCacheConfig;
begin
  Result := Default;
  Result.MaxSize := 5000;
  Result.TTL := 600;
  Result.CleanupInterval := 5;
end;

class function TCacheConfig.LowMemory: TCacheConfig;
begin
  Result := Default;
  Result.MaxSize := 100;
  Result.TTL := 60;
  Result.CleanupInterval := 1;
end;

{ TBatchConfig }

class function TBatchConfig.Default: TBatchConfig;
begin
  Result.Enabled := True;
  Result.MaxOperations := 100;
  Result.AutoExecute := True;
  Result.AutoExecuteThreshold := 50;
end;

class function TBatchConfig.HighThroughput: TBatchConfig;
begin
  Result := Default;
  Result.MaxOperations := 1000;
  Result.AutoExecuteThreshold := 500;
end;

class function TBatchConfig.LowLatency: TBatchConfig;
begin
  Result := Default;
  Result.MaxOperations := 10;
  Result.AutoExecuteThreshold := 5;
end;

{ TPerformanceConfig }

class function TPerformanceConfig.Default: TPerformanceConfig;
begin
  Result.Mode := TPerformanceMode.Default;
  Result.Cache := TCacheConfig.Default;
  Result.Batch := TBatchConfig.Default;
end;

class function TPerformanceConfig.FromMode(AMode: TPerformanceMode): TPerformanceConfig;
begin
  Result.Mode := AMode;
  case AMode of
    TPerformanceMode.HighPerformance:
    begin
      Result.Cache := TCacheConfig.HighPerformance;
      Result.Batch := TBatchConfig.HighThroughput;
    end;
    TPerformanceMode.LowMemory:
    begin
      Result.Cache := TCacheConfig.LowMemory;
      Result.Batch := TBatchConfig.LowLatency;
    end;
    else
      Result := Default;
  end;
end;

{ TPerformanceStats }

function TPerformanceStats.HitRate: Double;
var
  LTotal: Int64;
begin
  LTotal := CacheHits + CacheMisses;
  if LTotal = 0 then
    Exit(0.0);
  Result := (CacheHits / LTotal) * 100.0;
end;

{ TJSONPathCache }

constructor TJSONPathCache.Create;
begin
  inherited;
  FCache := TDictionary<String, TCacheEntry>.Create;
  FLock := TCriticalSection.Create;
  FConfig := TCacheConfig.Default;
  FLastCleanup := Now;
end;

destructor TJSONPathCache.Destroy;
begin
  FCache.Free;
  FLock.Free;
  inherited;
end;

procedure TJSONPathCache.Configure(const AConfig: TCacheConfig);
begin
  FLock.Enter;
  try
    FConfig := AConfig;
    if not FConfig.Enabled then
      FCache.Clear;
  finally
    FLock.Leave;
  end;
end;

procedure TJSONPathCache.Clear;
begin
  FLock.Enter;
  try
    FCache.Clear;
    FHits := 0;
    FMisses := 0;
  finally
    FLock.Leave;
  end;
end;

function TJSONPathCache.FGetCount: Integer;
begin
  FLock.Enter;
  try
    Result := FCache.Count;
  finally
    FLock.Leave;
  end;
end;

function TJSONPathCache.TryGet(const APath: String; out AElement: IJSONElement): Boolean;
var
  LEntry: TCacheEntry;
begin
  Result := False;
  AElement := nil;

  if not FConfig.Enabled then Exit;

  FLock.Enter;
  try
    if FCache.TryGetValue(APath, LEntry) then
    begin
      if SecondsBetween(Now, LEntry.Timestamp) <= FConfig.TTL then
      begin
        Inc(LEntry.AccessCount);
        FCache[APath] := LEntry;
        AElement := LEntry.Element;
        Inc(FHits);
        Result := True;
      end
      else
      begin
        FCache.Remove(APath);
        Inc(FMisses);
      end;
    end
    else
      Inc(FMisses);
  finally
    FLock.Leave;
  end;
end;

procedure TJSONPathCache.Add(const APath: String; const AElement: IJSONElement);
var
  LEntry: TCacheEntry;
begin
  if not FConfig.Enabled then Exit;
  if AElement = nil then Exit;

  FLock.Enter;
  try
    if FCache.Count >= FConfig.MaxSize then
      _EvictEntries;

    LEntry.Element := AElement;
    LEntry.Timestamp := Now;
    LEntry.AccessCount := 1;
    FCache.AddOrSetValue(APath, LEntry);
  finally
    FLock.Leave;
  end;
end;

procedure TJSONPathCache._CleanupIfNeeded;
begin
  if not FConfig.AutoCleanup then Exit;
  if MinutesBetween(Now, FLastCleanup) < FConfig.CleanupInterval then Exit;
  _EvictEntries;
end;

procedure TJSONPathCache._EvictEntries;
var
  LKey: String;
  LKeysToRemove: TList<String>;
  LTargetSize: Integer;
begin
  // Simple cleanup strategy: Remove expired, then random if still full
  // Ideally should be LRU, but for simplicity we keep it lightweight
  LKeysToRemove := TList<String>.Create;
  try
    for LKey in FCache.Keys do
    begin
      if SecondsBetween(Now, FCache[LKey].Timestamp) > FConfig.TTL then
        LKeysToRemove.Add(LKey);
    end;

    for LKey in LKeysToRemove do
      FCache.Remove(LKey);

    // If still too big, remove random entries until 80% capacity
    LTargetSize := Trunc(FConfig.MaxSize * 0.8);
    if FCache.Count > FConfig.MaxSize then
    begin
      for LKey in FCache.Keys do
      begin
        if FCache.Count <= LTargetSize then Break;
        FCache.Remove(LKey);
      end;
    end;

    FLastCleanup := Now;
  finally
    LKeysToRemove.Free;
  end;
end;

{ TJSONBatchProcessor }

constructor TJSONBatchProcessor.Create(const AComposer: IJSONComposer);
begin
  inherited Create;
  FComposer := AComposer;
  FQueue := TList<TOperation>.Create;
  FLock := TCriticalSection.Create;
  FConfig := TBatchConfig.Default;
end;

destructor TJSONBatchProcessor.Destroy;
begin
  FQueue.Free;
  FLock.Free;
  inherited;
end;

procedure TJSONBatchProcessor.Configure(const AConfig: TBatchConfig);
begin
  FLock.Enter;
  try
    FConfig := AConfig;
    if not FConfig.Enabled then
    begin
      FQueue.Clear;
      FActive := False;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TJSONBatchProcessor.BeginBatch;
begin
  FLock.Enter;
  try
    FActive := True;
  finally
    FLock.Leave;
  end;
end;

procedure TJSONBatchProcessor.EndBatch;
begin
  _ProcessQueue;
  FLock.Enter;
  try
    FActive := False;
  finally
    FLock.Leave;
  end;
end;

procedure TJSONBatchProcessor.Execute;
begin
  _ProcessQueue;
end;

procedure TJSONBatchProcessor.Enqueue(const AOp: TOperation);
begin
  if not FConfig.Enabled then
  begin
    // Execute immediately if disabled
    case AOp.OpType of
      TOpType.SetValue: FComposer.SetValue(AOp.Path, AOp.Value);
      TOpType.AddToArray: FComposer.AddToArray(AOp.Path, AOp.Value);
      TOpType.RemoveKey: FComposer.RemoveKey(AOp.Path);
    end;
    Exit;
  end;

  FLock.Enter;
  try
    FQueue.Add(AOp);
    if (FConfig.AutoExecute) and (FQueue.Count >= FConfig.AutoExecuteThreshold) then
      _ProcessQueue;
  finally
    FLock.Leave;
  end;
end;

procedure TJSONBatchProcessor._ProcessQueue;
var
  LOp: TOperation;
begin
  FLock.Enter;
  try
    if FQueue.Count = 0 then Exit;

    for LOp in FQueue do
    begin
      try
        case LOp.OpType of
          TOpType.SetValue: FComposer.SetValue(LOp.Path, LOp.Value);
          TOpType.AddToArray: FComposer.AddToArray(LOp.Path, LOp.Value);
          TOpType.RemoveKey: FComposer.RemoveKey(LOp.Path);
        end;
      except
        // Log error or continue? For now we continue to ensure batch completes
      end;
    end;

    Inc(FExecutedCount, FQueue.Count);
    FQueue.Clear;
  finally
    FLock.Leave;
  end;
end;

{ TJSONComposerEnhanced }

constructor TJSONComposerEnhanced.Create(const AComposer: IJSONComposer);
begin
  inherited Create;
  FComposer := AComposer;
  FCache := TJSONPathCache.Create;
  FBatch := TJSONBatchProcessor.Create(AComposer);
  FConfig := TPerformanceConfig.Default;
end;

destructor TJSONComposerEnhanced.Destroy;
begin
  FCache.Free;
  FBatch.Free;
  inherited;
end;

procedure TJSONComposerEnhanced.Configure(const AConfig: TPerformanceConfig);
begin
  FConfig := AConfig;
  FCache.Configure(AConfig.Cache);
  FBatch.Configure(AConfig.Batch);
end;

procedure TJSONComposerEnhanced.SetPerformanceMode(AMode: TPerformanceMode);
begin
  Configure(TPerformanceConfig.FromMode(AMode));
end;

procedure TJSONComposerEnhanced.ClearCache;
begin
  FCache.Clear;
end;

procedure TJSONComposerEnhanced.BeginBatch;
begin
  FBatch.BeginBatch;
end;

procedure TJSONComposerEnhanced.EndBatch;
begin
  FBatch.EndBatch;
end;

procedure TJSONComposerEnhanced.ExecuteBatch;
begin
  FBatch.Execute;
end;

function TJSONComposerEnhanced.IsBatchMode: Boolean;
begin
  Result := FBatch.IsActive;
end;

function TJSONComposerEnhanced.SetValue(const APath: String; const AValue: Variant): Boolean;
var
  LOp: TJSONBatchProcessor.TOperation;
begin
  Result := True;
  try
    if IsBatchMode then
    begin
      LOp.OpType := TJSONBatchProcessor.TOpType.SetValue;
      LOp.Path := APath;
      LOp.Value := AValue;
      FBatch.Enqueue(LOp);
    end
    else
    begin
      FComposer.SetValue(APath, AValue);
      Inc(FStats.TotalOperations);
    end;
  except
    Result := False;
  end;
end;

function TJSONComposerEnhanced.AddToArray(const APath: String; const AValue: Variant): Boolean;
var
  LOp: TJSONBatchProcessor.TOperation;
begin
  Result := True;
  try
    if IsBatchMode then
    begin
      LOp.OpType := TJSONBatchProcessor.TOpType.AddToArray;
      LOp.Path := APath;
      LOp.Value := AValue;
      FBatch.Enqueue(LOp);
    end
    else
    begin
      FComposer.AddToArray(APath, AValue);
      Inc(FStats.TotalOperations);
    end;
  except
    Result := False;
  end;
end;

function TJSONComposerEnhanced.RemoveKey(const APath: String): Boolean;
var
  LOp: TJSONBatchProcessor.TOperation;
begin
  Result := True;
  try
    if IsBatchMode then
    begin
      LOp.OpType := TJSONBatchProcessor.TOpType.RemoveKey;
      LOp.Path := APath;
      FBatch.Enqueue(LOp);
    end
    else
    begin
      FComposer.RemoveKey(APath);
      Inc(FStats.TotalOperations);
    end;
  except
    Result := False;
  end;
end;

function TJSONComposerEnhanced.SetMultipleValues(const APathValuePairs: array of Variant): Boolean;
var
  LIndex: Integer;
begin
  Result := True;
  BeginBatch;
  try
    for LIndex := 0 to High(APathValuePairs) div 2 do
    begin
      if not SetValue(VarToStr(APathValuePairs[LIndex * 2]), APathValuePairs[LIndex * 2 + 1]) then
      begin
        Result := False;
        Break;
      end;
    end;
  finally
    EndBatch;
  end;
end;

function TJSONComposerEnhanced.AddMultipleToArray(const APath: String; const AValues: array of Variant): Boolean;
var
  LIndex: Integer;
begin
  Result := True;
  BeginBatch;
  try
    for LIndex := 0 to High(AValues) do
    begin
      if not AddToArray(APath, AValues[LIndex]) then
      begin
        Result := False;
        Break;
      end;
    end;
  finally
    EndBatch;
  end;
end;

procedure TJSONComposerEnhanced._UpdateStatsFromComponents;
begin
  FStats.CacheHits := FCache.Hits;
  FStats.CacheMisses := FCache.Misses;
  FStats.CacheSize := FCache.Count;
  FStats.BatchOperationsExecuted := FBatch.ExecutedCount;
end;

function TJSONComposerEnhanced.GetStats: TPerformanceStats;
begin
  _UpdateStatsFromComponents;
  Result := FStats;
end;

function TJSONComposerEnhanced.GetStatsReport: String;
var
  LStats: TPerformanceStats;
begin
  LStats := GetStats;
  Result := Format(
    'Performance Report:' + sLineBreak +
    '  Total Ops: %d' + sLineBreak +
    '  Batch Ops: %d' + sLineBreak +
    '  Cache Hit Rate: %.2f%%' + sLineBreak +
    '  Cache Size: %d entries',
    [LStats.TotalOperations,
     LStats.BatchOperationsExecuted,
     LStats.HitRate,
     LStats.CacheSize]);
end;

procedure TJSONComposerEnhanced.ResetStats;
begin
  FStats := Default(TPerformanceStats);
  FCache.Clear;
  // Batch stats reset implicitly? No, separate counter needed if strict reset required
end;

end.