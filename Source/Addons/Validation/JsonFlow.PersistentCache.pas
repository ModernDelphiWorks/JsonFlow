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

unit JsonFlow.PersistentCache;

{
  Este arquivo implementa um sistema de cache persistente que permite
  armazenar resultados de validação em disco para reutilização entre
  sessões da aplicação.
  
  Funcionalidades:
  - Cache baseado em hash do schema e dados
  - Persistência em arquivo JSON
  - Expiração automática de entradas antigas
  - Thread-safety
  - Compressão opcional
}

interface

uses
  SysUtils,
  Classes,
  Generics.Collections,
  SyncObjs,
  DateUtils,
  Hash,
  JsonFlow.Interfaces,
  JsonFlow.Reader,
  JsonFlow.Composer,
  JsonFlow.Objects,
  JsonFlow.Arrays,
  JsonFlow.Value,
  JsonFlow.Serializer,
  JsonFlow.Utils
  {$IFDEF USE_STRATUM},
  Stratum.Cache
  {$ENDIF};

type
  // Sistema de cache persistente
  TPersistentCache = class
  public type
    // Configurações do cache
    TConfig = record
      MaxEntries: Integer;
      ExpirationDays: Integer;
      CacheFilePath: string;
      CompressionEnabled: Boolean;
      AutoSave: Boolean;
      SaveIntervalMinutes: Integer;
    end;
  private type
    // Entrada do cache persistente
    TEntry = record
      Hash: string;
      IsValid: Boolean;
      ErrorCount: Integer;
      CreatedAt: TDateTime;
      LastAccessed: TDateTime;
      AccessCount: Integer;
    end;
  private
    {$IFDEF USE_STRATUM}
    FCache: Stratum.Cache.TPersistentCache;
    {$ELSE}
    FMemoryCache: TDictionary<string, string>;
    {$ENDIF}
    FConfig: TConfig;
    FLock: TCriticalSection;
    FSerializer: TJSONSerializer;
    function _GenerateHash(const ASchema, AData: string): string;
    function _EntryToJson(const AEntry: TEntry): string;
    function _JsonToEntry(const AJson: string): TEntry;
  public
    constructor Create(const AConfig: TConfig);
    destructor Destroy; override;
    // Operações do cache
    function TryGetValidation(const ASchema, AData: string; out AIsValid: Boolean; out AErrorCount: Integer): Boolean;
    procedure StoreValidation(const ASchema, AData: string; AIsValid: Boolean; AErrorCount: Integer);
    // Gerenciamento
    procedure Clear;
    procedure Flush;
    procedure Cleanup;
    // Estatísticas
    function GetCacheSize: Integer;
    function GetHitRate: Double; // Not supported directly by simple Stratum Cache yet, but can be inferred or removed
    function GetOldestEntry: TDateTime; // Not supported efficiently
    function GetNewestEntry: TDateTime; // Not supported efficiently
    // Configuração
    property Config: TConfig read FConfig write FConfig;
  end;

  // Singleton para acesso global
  TGlobalPersistentCache = class
  private
    class var FInstance: TPersistentCache;
    class var FLock: TCriticalSection;
  public
    class function Instance: TPersistentCache;
    class procedure Initialize(const AConfig: TPersistentCache.TConfig);
    class procedure Finalize;
  end;

implementation

{ TPersistentCache }

constructor TPersistentCache.Create(const AConfig: TConfig);
begin
  inherited Create;
  FConfig := AConfig;
  FLock := TCriticalSection.Create;
  FSerializer := TJSONSerializer.Create;
  
  {$IFDEF USE_STRATUM}
  // Use Stratum Cache
  // Convert ExpirationDays to minutes for Stratum
  FCache := Stratum.Cache.TPersistentCache.Create(
    FConfig.CacheFilePath,
    FConfig.ExpirationDays * 24 * 60
  );
  {$ELSE}
  // Fallback to memory cache
  FMemoryCache := TDictionary<string, string>.Create;
  {$ENDIF}
end;

destructor TPersistentCache.Destroy;
begin
  {$IFDEF USE_STRATUM}
  FCache.Free;
  {$ELSE}
  FMemoryCache.Free;
  {$ENDIF}
  FLock.Free;
  FSerializer.Free;
  inherited Destroy;
end;

function TPersistentCache._GenerateHash(const ASchema, AData: string): string;
var
  LCombined: string;
begin
  LCombined := ASchema + '|' + AData;
  Result := THashSHA1.GetHashString(LCombined);
end;

function TPersistentCache._EntryToJson(const AEntry: TEntry): string;
var
  LJson: IJSONObject;
begin
  LJson := TJSONObject.Create;
  LJson.Add('h', AEntry.Hash);
  LJson.Add('v', AEntry.IsValid);
  LJson.Add('e', AEntry.ErrorCount);
  LJson.Add('c', DateTimeToIso8601(AEntry.CreatedAt, True));
  LJson.Add('l', DateTimeToIso8601(AEntry.LastAccessed, True));
  LJson.Add('a', AEntry.AccessCount);
  Result := LJson.ToJSON;
end;

function TPersistentCache._JsonToEntry(const AJson: string): TEntry;
var
  LJson: IJSONValue;
  LObj: IJSONObject;
begin
  Result := Default(TEntry);
  if AJson = '' then Exit;

  LJson := TJSONReader.Parse(AJson);
  if Supports(LJson, IJSONObject, LObj) then
  begin
    if LObj.ContainsKey('h') then Result.Hash := LObj.GetValue('h').AsString;
    if LObj.ContainsKey('v') then Result.IsValid := LObj.GetValue('v').AsBoolean;
    if LObj.ContainsKey('e') then Result.ErrorCount := LObj.GetValue('e').AsInteger;
    if LObj.ContainsKey('c') then Result.CreatedAt := Iso8601ToDateTime(LObj.GetValue('c').AsString, True);
    if LObj.ContainsKey('l') then Result.LastAccessed := Iso8601ToDateTime(LObj.GetValue('l').AsString, True);
    if LObj.ContainsKey('a') then Result.AccessCount := LObj.GetValue('a').AsInteger;
  end;
end;

function TPersistentCache.TryGetValidation(const ASchema, AData: string; out AIsValid: Boolean; out AErrorCount: Integer): Boolean;
var
  LHash: string;
  LJsonEntry: string;
  LEntry: TEntry;
begin
  Result := False;
  AIsValid := False;
  AErrorCount := 0;
  
  LHash := _GenerateHash(ASchema, AData);
  
  {$IFDEF USE_STRATUM}
  if FCache.Get(LHash, LJsonEntry) then
  begin
    LEntry := _JsonToEntry(LJsonEntry);
    
    // Update access stats
    LEntry.LastAccessed := Now;
    Inc(LEntry.AccessCount);
    
    // Update in cache
    FCache.Put(LHash, _EntryToJson(LEntry));
    
    AIsValid := LEntry.IsValid;
    AErrorCount := LEntry.ErrorCount;
    Result := True;
  end;
  {$ELSE}
  FLock.Enter;
  try
    if FMemoryCache.TryGetValue(LHash, LJsonEntry) then
    begin
      LEntry := _JsonToEntry(LJsonEntry);
      
      // Update access stats
      LEntry.LastAccessed := Now;
      Inc(LEntry.AccessCount);
      
      // Update in memory cache
      FMemoryCache.AddOrSetValue(LHash, _EntryToJson(LEntry));
      
      AIsValid := LEntry.IsValid;
      AErrorCount := LEntry.ErrorCount;
      Result := True;
    end;
  finally
    FLock.Leave;
  end;
  {$ENDIF}
end;

procedure TPersistentCache.StoreValidation(const ASchema, AData: string; AIsValid: Boolean; AErrorCount: Integer);
var
  LHash: string;
  LEntry: TEntry;
begin
  LHash := _GenerateHash(ASchema, AData);
  
  LEntry.Hash := LHash;
  LEntry.IsValid := AIsValid;
  LEntry.ErrorCount := AErrorCount;
  LEntry.CreatedAt := Now;
  LEntry.LastAccessed := Now;
  LEntry.AccessCount := 1;
  
  {$IFDEF USE_STRATUM}
  FCache.Put(LHash, _EntryToJson(LEntry));
  {$ELSE}
  FLock.Enter;
  try
    FMemoryCache.AddOrSetValue(LHash, _EntryToJson(LEntry));
  finally
    FLock.Leave;
  end;
  {$ENDIF}
end;

procedure TPersistentCache.Clear;
begin
  {$IFDEF USE_STRATUM}
  FCache.Clear;
  {$ELSE}
  FLock.Enter;
  try
    FMemoryCache.Clear;
  finally
    FLock.Leave;
  end;
  {$ENDIF}
end;

procedure TPersistentCache.Flush;
begin
  {$IFDEF USE_STRATUM}
  FCache.Flush;
  {$ELSE}
  // Memory cache doesn't persist, so nothing to flush
  {$ENDIF}
end;

procedure TPersistentCache.Cleanup;
begin
  // Stratum Cache handles cleanup automatically on access/put, 
  // but we can trigger it if exposed.
  // For now, no explicit cleanup needed as it's automatic.
end;

function TPersistentCache.GetCacheSize: Integer;
begin
  {$IFDEF USE_STRATUM}
  Result := FCache.Count;
  {$ELSE}
  FLock.Enter;
  try
    Result := FMemoryCache.Count;
  finally
    FLock.Leave;
  end;
  {$ENDIF}
end;

function TPersistentCache.GetHitRate: Double;
begin
  Result := 0; // Not tracked by Stratum Cache yet
end;

function TPersistentCache.GetOldestEntry: TDateTime;
begin
  Result := 0; // Not tracked efficiently
end;

function TPersistentCache.GetNewestEntry: TDateTime;
begin
  Result := 0; // Not tracked efficiently
end;

{ TGlobalPersistentCache }

class function TGlobalPersistentCache.Instance: TPersistentCache;
var
  LConfig: TPersistentCache.TConfig;
begin
  if not Assigned(FInstance) then
  begin
    FLock.Enter;
    try
      if not Assigned(FInstance) then
      begin
        // Configuração padrão
        LConfig.MaxEntries := 10000;
        LConfig.ExpirationDays := 30;
        LConfig.CacheFilePath := ExtractFilePath(ParamStr(0)) + 'jsonflow_cache.json';
        LConfig.CompressionEnabled := False;
        LConfig.AutoSave := True;
        LConfig.SaveIntervalMinutes := 5;
        
        FInstance := TPersistentCache.Create(LConfig);
      end;
    finally
      FLock.Leave;
    end;
  end;
  
  Result := FInstance;
end;

class procedure TGlobalPersistentCache.Initialize(const AConfig: TPersistentCache.TConfig);
begin
  FLock.Enter;
  try
    if Assigned(FInstance) then
      FInstance.Free;
      
    FInstance := TPersistentCache.Create(AConfig);
  finally
    FLock.Leave;
  end;
end;

class procedure TGlobalPersistentCache.Finalize;
begin
  FLock.Enter;
  try
    if Assigned(FInstance) then
    begin
      FInstance.Free;
      FInstance := nil;
    end;
  finally
    FLock.Leave;
  end;
end;

initialization
  TGlobalPersistentCache.FLock := TCriticalSection.Create;

finalization
  TGlobalPersistentCache.Finalize;
  TGlobalPersistentCache.FLock.Free;

end.
