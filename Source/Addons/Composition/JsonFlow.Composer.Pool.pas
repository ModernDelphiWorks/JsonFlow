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

unit JsonFlow.Composer.Pool;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.SyncObjs,
  JsonFlow.Interfaces,
  JsonFlow.Composer
  {$IFDEF USE_STRATUM},
  Stratum.Pool
  {$ENDIF}; // Usando o Pool Genérico do Stratum

type
  // JSON Composer Pool
  TJSONComposerPool = class
  public type
    // Pool Statistics (Mantido para compatibilidade, mas mapeado do Stratum)
    TPoolStats = record
      TotalCreated: Integer;
      TotalDestroyed: Integer; // Não usado no Stratum
      CurrentInPool: Integer;
      CurrentInUse: Integer; // Não rastreado diretamente no Stratum simples, calculado
      MaxPoolSize: Integer;
      HitRate: Double; // Calculado
      TotalBorrows: Integer; // Mapeado de ReuseTotal + CreatedTotal
      TotalReturns: Integer; // ReuseTotal
    end;

    // Pool Configuration
    TPoolConfiguration = record
      MaxSize: Integer;
      PreAllocate: Integer;
      AutoCleanup: Boolean; // Ignorado no Stratum por enquanto
      CleanupInterval: Integer; // Ignorado
      EnableStats: Boolean; // Sempre ativo no Stratum
      class function Default: TPoolConfiguration; static;
    end;

  private
    {$IFDEF USE_STRATUM}
    FPool: TObjectPool<TJSONComposer>; // O Pool Genérico requer classe concreta com construtor
    {$ENDIF}
    FConfig: TPoolConfiguration;
    FCreateComposerFunc: TFunc<IJSONComposer>; // Mantido, mas adaptador necessário
    
  public
    constructor Create(const ACreateFunc: TFunc<IJSONComposer> = nil);
    destructor Destroy; override;
    
    function BorrowComposer: IJSONComposer;
    procedure ReturnComposer(const AComposer: IJSONComposer);
    
    function GetStats: TPoolStats;
    function GetStatsAsString: String;
    procedure Clear;
    procedure Configure(const AConfig: TPoolConfiguration);
  end;

  // Pooled Composer with automatic return
  TPooledJSONComposer = class
  private
    FPool: TJSONComposerPool;
    FComposer: IJSONComposer;
  public
    constructor Create(const APool: TJSONComposerPool);
    destructor Destroy; override;
    property Composer: IJSONComposer read FComposer;
  end;

  // Global Pool Singleton
  TGlobalJSONComposerPool = class
  private
    class var FInstance: TJSONComposerPool;
    class var FLock: TCriticalSection;
  public
    class function Instance: TJSONComposerPool;
    class procedure FreeInstance;
    class procedure Configure(const AConfig: TJSONComposerPool.TPoolConfiguration);
    class constructor Create;
    class destructor Destroy;
  end;

implementation

{ TJSONComposerPool.TPoolConfiguration }

class function TJSONComposerPool.TPoolConfiguration.Default: TPoolConfiguration;
begin
  Result.MaxSize := 10;
  Result.PreAllocate := 2;
  Result.AutoCleanup := True;
  Result.CleanupInterval := 30;
  Result.EnableStats := True;
end;

{ TJSONComposerPool }

constructor TJSONComposerPool.Create(const ACreateFunc: TFunc<IJSONComposer>);
begin
  inherited Create;
  FConfig := TPoolConfiguration.Default;
  FCreateComposerFunc := ACreateFunc;
  
  {$IFDEF USE_STRATUM}
  FPool := TObjectPool<TJSONComposer>.Create(FConfig.MaxSize, FConfig.PreAllocate, True);
  {$ENDIF}
end;

destructor TJSONComposerPool.Destroy;
begin
  {$IFDEF USE_STRATUM}
  FPool.Free;
  {$ENDIF}
  inherited;
end;

function TJSONComposerPool.BorrowComposer: IJSONComposer;
begin
  {$IFDEF USE_STRATUM}
  // Usa o pool se Stratum estiver habilitado
  Result := FPool.Get;
  {$ELSE}
  // Cria uma nova instância se Stratum estiver desabilitado (sem pool)
  // Nota: TJSONComposer é uma classe concreta assumida aqui.
  // Se ACreateFunc for fornecido, usamos ele (assumindo que retorna uma nova instância).
  if Assigned(FCreateComposerFunc) then
    Result := FCreateComposerFunc()
  else
    Result := TJSONComposer.Create;
  {$ENDIF}
end;

procedure TJSONComposerPool.ReturnComposer(const AComposer: IJSONComposer);
{$IFDEF USE_STRATUM}
var
  LObj: TObject;
{$ENDIF}
begin
  if AComposer = nil then Exit;
  
  {$IFDEF USE_STRATUM}
  // Cast para objeto para devolver ao pool
  LObj := AComposer as TObject;
  if LObj is TJSONComposer then
  begin
    // Limpa o estado antes de devolver (TJSONComposer deve implementar Clear)
    AComposer.Clear;
    FPool.Release(TJSONComposer(LObj));
  end;
  {$ELSE}
  // Se não usa pool, não faz nada. 
  // O objeto será liberado automaticamente quando a referência da interface sair de escopo.
  // Como BorrowComposer cria uma nova instância gerenciada por interface, 
  // o contador de referência cuidará da destruição.
  {$ENDIF}
end;

function TJSONComposerPool.GetStats: TPoolStats;
begin
  {$IFDEF USE_STRATUM}
  Result.TotalCreated := Integer(FPool.CreatedTotal);
  Result.TotalReturns := Integer(FPool.ReuseTotal);
  Result.TotalBorrows := Result.TotalCreated + Result.TotalReturns;
  Result.CurrentInPool := FPool.Count;
  Result.MaxPoolSize := FPool.MaxSize;
  
  if Result.TotalBorrows > 0 then
    Result.HitRate := (Result.TotalReturns / Result.TotalBorrows) * 100
  else
    Result.HitRate := 0;
    
  // Estimativa
  Result.CurrentInUse := Result.TotalBorrows - Result.TotalReturns;
  {$ELSE}
  // Retorna zerado se não houver pool
  FillChar(Result, SizeOf(Result), 0);
  {$ENDIF}
end;

function TJSONComposerPool.GetStatsAsString: String;
var
  LStats: TPoolStats;
begin
  LStats := GetStats;
  Result := Format('Pool Stats: Created=%d, InPool=%d, Reuse=%d, HitRate=%.1f%%',
    [LStats.TotalCreated, LStats.CurrentInPool, LStats.TotalReturns, LStats.HitRate]);
end;

procedure TJSONComposerPool.Clear;
begin
  {$IFDEF USE_STRATUM}
  FPool.Clear;
  {$ENDIF}
end;

procedure TJSONComposerPool.Configure(const AConfig: TPoolConfiguration);
begin
  FConfig := AConfig;
end;

{ TPooledJSONComposer }

constructor TPooledJSONComposer.Create(const APool: TJSONComposerPool);
begin
  inherited Create;
  FPool := APool;
  FComposer := FPool.BorrowComposer;
end;

destructor TPooledJSONComposer.Destroy;
begin
  if Assigned(FPool) and Assigned(FComposer) then
    FPool.ReturnComposer(FComposer);
  inherited;
end;

{ TGlobalJSONComposerPool }

class constructor TGlobalJSONComposerPool.Create;
begin
  FLock := TCriticalSection.Create;
end;

class destructor TGlobalJSONComposerPool.Destroy;
begin
  FreeInstance;
  FLock.Free;
end;

class function TGlobalJSONComposerPool.Instance: TJSONComposerPool;
begin
  if not Assigned(FInstance) then
  begin
    FLock.Enter;
    try
      if not Assigned(FInstance) then
        FInstance := TJSONComposerPool.Create;
    finally
      FLock.Leave;
    end;
  end;
  Result := FInstance;
end;

class procedure TGlobalJSONComposerPool.FreeInstance;
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

class procedure TGlobalJSONComposerPool.Configure(const AConfig: TJSONComposerPool.TPoolConfiguration);
begin
  Instance.Configure(AConfig);
end;

end.
