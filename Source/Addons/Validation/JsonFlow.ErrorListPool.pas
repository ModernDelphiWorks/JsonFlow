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

unit JsonFlow.ErrorListPool;

interface

uses
  System.Generics.Collections,
  System.SyncObjs,
  JsonFlow.Objects,
  JsonFlow.Interfaces
  {$IFDEF USE_STRATUM},
  Stratum.Pool
  {$ENDIF}; // Usando o novo Pool Genérico

type
  /// <summary>
  /// Pool de listas de erro para otimização de performance
  /// Reutiliza listas ao invés de criar/destruir constantemente
  /// </summary>
  TErrorListPool = class
  private
    class var FInstance: TErrorListPool;
    class var FLockInstance: TCriticalSection;
  private
    {$IFDEF USE_STRATUM}
    FPool: TObjectPool<TList<TValidationError>>;
    {$ENDIF}
  public
    constructor Create;
    destructor Destroy; override;
    class function Instance: TErrorListPool;
    class procedure FreeInstance;
    
    /// <summary>
    /// Obtém uma lista do pool ou cria uma nova se necessário
    /// </summary>
    function GetList: TList<TValidationError>;
    
    /// <summary>
    /// Retorna uma lista para o pool para reutilização
    /// </summary>
    procedure ReturnList(AList: TList<TValidationError>);
    
    /// <summary>
    /// Limpa o pool liberando todas as listas
    /// </summary>
    procedure Clear;
    
    /// <summary>
    /// Retorna estatísticas do pool
    /// </summary>
    procedure GetStats(out APoolSize, ACreatedCount, AReuseCount: Integer);
    
    {$IFDEF USE_STRATUM}
    property Pool: TObjectPool<TList<TValidationError>> read FPool;
    {$ENDIF}
  end;

implementation

uses
  System.SysUtils;

{ TErrorListPool }

constructor TErrorListPool.Create;
begin
  inherited;
  {$IFDEF USE_STRATUM}
  // Cria pool com tamanho 50, sem pré-alocação, e dono dos objetos
  FPool := TObjectPool<TList<TValidationError>>.Create(50, 0, True);
  {$ENDIF}
end;

destructor TErrorListPool.Destroy;
begin
  {$IFDEF USE_STRATUM}
  FPool.Free;
  {$ENDIF}
  inherited;
end;

class function TErrorListPool.Instance: TErrorListPool;
begin
  if not Assigned(FInstance) then
  begin
    if not Assigned(FLockInstance) then
      FLockInstance := TCriticalSection.Create;
      
    FLockInstance.Enter;
    try
      if not Assigned(FInstance) then
        FInstance := TErrorListPool.Create;
    finally
      FLockInstance.Leave;
    end;
  end;
  Result := FInstance;
end;

class procedure TErrorListPool.FreeInstance;
begin
  if Assigned(FLockInstance) then
  begin
    FLockInstance.Enter;
    try
      if Assigned(FInstance) then
      begin
        FInstance.Free;
        FInstance := nil;
      end;
    finally
      FLockInstance.Leave;
    end;
    FLockInstance.Free;
    FLockInstance := nil;
  end;
end;

function TErrorListPool.GetList: TList<TValidationError>;
begin
  {$IFDEF USE_STRATUM}
  Result := FPool.Get;
  Result.Clear; // Garante lista limpa
  {$ELSE}
  Result := TList<TValidationError>.Create;
  {$ENDIF}
end;

procedure TErrorListPool.ReturnList(AList: TList<TValidationError>);
begin
  if not Assigned(AList) then
    Exit;
    
  {$IFDEF USE_STRATUM}
  AList.Clear;
  FPool.Release(AList);
  {$ELSE}
  AList.Free;
  {$ENDIF}
end;

procedure TErrorListPool.Clear;
begin
  {$IFDEF USE_STRATUM}
  FPool.Clear;
  {$ENDIF}
end;

procedure TErrorListPool.GetStats(out APoolSize, ACreatedCount, AReuseCount: Integer);
begin
  {$IFDEF USE_STRATUM}
  APoolSize := FPool.Count;
  ACreatedCount := Integer(FPool.CreatedTotal); // Cast seguro para Integer
  AReuseCount := Integer(FPool.ReuseTotal);
  {$ELSE}
  APoolSize := 0;
  ACreatedCount := 0;
  AReuseCount := 0;
  {$ENDIF}
end;

initialization
  TErrorListPool.FLockInstance := TCriticalSection.Create;

finalization
  try
    TErrorListPool.FreeInstance;
  except
    // Ignora erros durante finalização
  end;

end.
