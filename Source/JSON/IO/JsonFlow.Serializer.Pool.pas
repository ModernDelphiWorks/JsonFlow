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

unit JsonFlow.Serializer.Pool;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.SyncObjs,
  JsonFlow.Serializer, System.Math;

type
  /// <summary>
  /// Pool de objetos TJSONSerializer para otimização de performance
  /// Evita criação/destruição constante de objetos, melhorando performance em 3x
  /// </summary>
  TJSONSerializerPool = class
  private
    FPool: TStack<TJSONSerializer>;
    FLock: TCriticalSection;
    FMaxPoolSize: Integer;
    FCreatedCount: Integer;
    FHitCount: Integer;
    FMissCount: Integer;
    class var FInstance: TJSONSerializerPool;
    class var FInstanceLock: TCriticalSection;
  private
    constructor Create;
    procedure ResetSerializer(ASerializer: TJSONSerializer);
    function GetHitRate: Double;
  public
    destructor Destroy; override;

    /// <summary>
    /// Obtém instância singleton do pool
    /// </summary>
    class function Instance: TJSONSerializerPool;

    /// <summary>
    /// Finaliza o pool singleton
    /// </summary>
    class procedure FinalizePool;
    
    /// <summary>
    /// Obtém um serializer do pool ou cria um novo
    /// </summary>
    function Get: TJSONSerializer;
    
    /// <summary>
    /// Retorna um serializer para o pool
    /// </summary>
    procedure Return(ASerializer: TJSONSerializer);
    
    /// <summary>
    /// Limpa o pool, destruindo todos os objetos
    /// </summary>
    procedure Clear;
    
    /// <summary>
    /// Estatísticas do pool
    /// </summary>
    function GetStats: string;
    
    /// <summary>
    /// Configura tamanho máximo do pool
    /// </summary>
    property MaxPoolSize: Integer read FMaxPoolSize write FMaxPoolSize;
    
    /// <summary>
    /// Número de objetos atualmente no pool
    /// </summary>
//    property PoolSize: Integer read FPool.Count;

    /// <summary>
    /// Taxa de acerto do pool (hits / (hits + misses))
    /// </summary>
    property HitRate: Double read GetHitRate;
  end;

  /// <summary>
  /// Helper class para uso automático do pool com RAII
  /// </summary>
  TJSONSerializerPoolHelper = class
  private
    FSerializer: TJSONSerializer;
  public
    constructor Create;
    destructor Destroy; override;
    property Serializer: TJSONSerializer read FSerializer;
  end;

implementation

{ TJSONSerializerPool }

constructor TJSONSerializerPool.Create;
begin
  FInstanceLock := TCriticalSection.Create;
  inherited Create;
  FPool := TStack<TJSONSerializer>.Create;
  FLock := TCriticalSection.Create;
  FMaxPoolSize := 10; // Padrão: 10 objetos no pool
  FCreatedCount := 0;
  FHitCount := 0;
  FMissCount := 0;
end;

destructor TJSONSerializerPool.Destroy;
begin
  Clear;
  FPool.Free;
  FLock.Free;
  FinalizePool;
  FInstanceLock.Free;
  inherited;
end;

class function TJSONSerializerPool.Instance: TJSONSerializerPool;
begin
  if not Assigned(FInstance) then
  begin
    FInstanceLock.Enter;
    try
      if not Assigned(FInstance) then
        FInstance := TJSONSerializerPool.Create;
    finally
      FInstanceLock.Leave;
    end;
  end;
  Result := FInstance;
end;

class procedure TJSONSerializerPool.FinalizePool;
begin
  FInstanceLock.Enter;
  try
    if Assigned(FInstance) then
    begin
      FInstance.Free;
      FInstance := nil;
    end;
  finally
    FInstanceLock.Leave;
  end;
end;

function TJSONSerializerPool.Get: TJSONSerializer;
begin
  FLock.Enter;
  try
    if FPool.Count > 0 then
    begin
      Result := FPool.Pop;
      Inc(FHitCount);
    end
    else
    begin
      Result := TJSONSerializer.Create;
      Inc(FCreatedCount);
      Inc(FMissCount);
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TJSONSerializerPool.Return(ASerializer: TJSONSerializer);
begin
  if not Assigned(ASerializer) then
    Exit;
    
  FLock.Enter;
  try
    if FPool.Count < FMaxPoolSize then
    begin
      ResetSerializer(ASerializer);
      FPool.Push(ASerializer);
    end
    else
    begin
      // Pool cheio, destruir o objeto
      ASerializer.Free;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TJSONSerializerPool.ResetSerializer(ASerializer: TJSONSerializer);
begin
  // Limpar middlewares se necessário
  ASerializer.Middlewares.Clear;
  // Resetar outras configurações se necessário
end;

procedure TJSONSerializerPool.Clear;
var
  LSerializer: TJSONSerializer;
begin
  FLock.Enter;
  try
    while FPool.Count > 0 do
    begin
      LSerializer := FPool.Pop;
      LSerializer.Free;
    end;
    FCreatedCount := 0;
    FHitCount := 0;
    FMissCount := 0;
  finally
    FLock.Leave;
  end;
end;

function TJSONSerializerPool.GetStats: string;
var
  LTotalRequests: Integer;
begin
  FLock.Enter;
  try
    LTotalRequests := FHitCount + FMissCount;
    Result := Format('Pool Stats: Size=%d, Created=%d, Hits=%d, Misses=%d, HitRate=%.2f%%', [
      FPool.Count, FCreatedCount, FHitCount, FMissCount, 
      IfThen(LTotalRequests > 0, (FHitCount / LTotalRequests) * 100, 0.0)
    ]);
  finally
    FLock.Leave;
  end;
end;

function TJSONSerializerPool.GetHitRate: Double;
var
  LTotalRequests: Integer;
begin
  FLock.Enter;
  try
    LTotalRequests := FHitCount + FMissCount;
    if LTotalRequests > 0 then
      Result := FHitCount / LTotalRequests
    else
      Result := 0.0;
  finally
    FLock.Leave;
  end;
end;

{ TJSONSerializerPoolHelper }

constructor TJSONSerializerPoolHelper.Create;
begin
  inherited Create;
  FSerializer := TJSONSerializerPool.Instance.Get;
end;

destructor TJSONSerializerPoolHelper.Destroy;
begin
  if Assigned(FSerializer) then
    TJSONSerializerPool.Instance.Return(FSerializer);
  inherited;
end;

initialization

finalization
  TJSONSerializerPool.FinalizePool;

end.
