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

unit JsonFlow.AsyncValidator;

{
  JsonFlow4D - Sistema de Validação Assíncrona
  
  Este arquivo implementa um sistema de validação assíncrona que permite
  validar múltiplos documentos JSON em paralelo, melhorando significativamente
  a performance para grandes volumes de dados.
}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.SyncObjs,
  System.Threading,
  JsonFlow.Interfaces,
  JsonFlow.SchemaValidator,
  JsonFlow.Reader;

{$SCOPEDENUMS ON}

type
  // Validador assíncrono principal
  TAsyncValidator = class
  public type
    // Prioridade da tarefa de validação
    TPriority = (
      Low,
      Normal,
      High,
      Critical
    );
    // Status da validação assíncrona
    TStatus = (
      Queued,
      Running,
      Completed,
      Cancelled,
      Error
    );
    // Resultado da validação assíncrona
    TResult = record
      TaskId: string;
      Status: TStatus;
      IsValid: Boolean;
      Errors: TList<TValidationError>;
      StartTime: TDateTime;
      EndTime: TDateTime;
      ErrorMessage: string;
    end;
    // Callback para progresso
    TProgressCallback = procedure(const ATaskId: string; AProgress: Integer; ATotal: Integer) of object;
    // Callback para conclusão
    TCompletedCallback = procedure(const AResult: TResult) of object;
    // Configurações do validador assíncrono
    TConfig = record
      MaxThreads: Integer;
      QueueCapacity: Integer;
      TaskTimeoutSeconds: Integer;
      EnablePrioritization: Boolean;
      EnableLoadBalancing: Boolean;
      ThreadIdleTimeoutSeconds: Integer;
    end;
    // Estatísticas do validador assíncrono
    TStats = record
      TotalTasks: Integer;
      CompletedTasks: Integer;
      FailedTasks: Integer;
      CancelledTasks: Integer;
      QueuedTasks: Integer;
      RunningTasks: Integer;
      AverageExecutionTime: Double;
      ThroughputPerSecond: Double;
      ActiveThreads: Integer;
    end;
  private type
    // Tarefa de validação (Interna)
    TTask = class
    private
      FTaskId: string;
      FJsonData: string;
      FSchema: IJSONElement;
      FPriority: TPriority;
      FProgressCallback: TProgressCallback;
      FCompletedCallback: TCompletedCallback;
      FCreatedAt: TDateTime;
      FCancelled: Boolean;
    public
      constructor Create(const ATaskId: string; const AJsonData: string;
                       const ASchema: IJSONElement; APriority: TPriority;
                       AProgressCallback: TProgressCallback;
                       ACompletedCallback: TCompletedCallback;
                       ACancelled: Boolean = False);

      property TaskId: string read FTaskId;
      property JsonData: string read FJsonData;
      property Schema: IJSONElement read FSchema;
      property Priority: TPriority read FPriority;
      property ProgressCallback: TProgressCallback read FProgressCallback;
      property CompletedCallback: TCompletedCallback read FCompletedCallback;
      property CreatedAt: TDateTime read FCreatedAt;
      property Cancelled: Boolean read FCancelled write FCancelled;
    end;

    // Worker thread para validação (Interna)
    TWorkerThread = class(TThread)
    private
      FValidator: TJSONSchemaValidator;
      FTaskQueue: TThreadedQueue<TTask>;
      FStats: TStats;
      FStatsLock: TCriticalSection;
      FIdleTimeout: Integer;
      procedure _UpdateStats(const ATask: TTask; const AResult: TResult);
    protected
      procedure Execute; override;
    public
      constructor Create(ATaskQueue: TThreadedQueue<TTask>;
                       AIdleTimeout: Integer);
      destructor Destroy; override;
      function GetStats: TStats;
    end;
  private
    FConfig: TConfig;
    FTaskQueue: TThreadedQueue<TTask>;
    FWorkerThreads: TList<TWorkerThread>;
    FRunningTasks: TDictionary<string, TTask>;
    FCompletedTasks: TDictionary<string, TResult>;
    FLock: TCriticalSection;
    FActive: Boolean;
    FTaskCounter: Integer;
    function _GenerateTaskId: string;
    procedure _StartWorkerThreads;
    procedure _StopWorkerThreads;
  public
    constructor Create(const AConfig: TConfig);
    destructor Destroy; override;
    // Controle do validador
    procedure Start;
    procedure Stop;
    procedure Pause;
    procedure Resume;
    // Submissão de tarefas
    function SubmitValidation(const AJsonData: string; const ASchema: IJSONElement;
                             APriority: TPriority = TPriority.Normal;
                             AProgressCallback: TProgressCallback = nil;
                             ACompletedCallback: TCompletedCallback = nil): string;

    function SubmitBatchValidation(const AJsonDataList: TArray<string>;
                                  const ASchema: IJSONElement;
                                  APriority: TPriority = TPriority.Normal;
                                  AProgressCallback: TProgressCallback = nil;
                                  ACompletedCallback: TCompletedCallback = nil): TArray<string>;
    // Controle de tarefas
    function CancelTask(const ATaskId: string): Boolean;
    function GetTaskStatus(const ATaskId: string): TStatus;
    function GetTaskResult(const ATaskId: string): TResult;
    function WaitForTask(const ATaskId: string; ATimeoutMs: Integer = -1): Boolean;
    function WaitForAllTasks(ATimeoutMs: Integer = -1): Boolean;
    // Estatísticas e monitoramento
    function GetStats: TStats;
    function GetQueueSize: Integer;
    function GetActiveThreadCount: Integer;
    // Configuração
    property Config: TConfig read FConfig write FConfig;
    property Active: Boolean read FActive;
  end; 
  // Singleton para acesso global
  TGlobalAsyncValidator = class
  private
    class var FInstance: TAsyncValidator;
    class var FLock: TCriticalSection;    
  public
    class function Instance: TAsyncValidator;
    class procedure Initialize(const AConfig: TAsyncValidator.TConfig);
    class procedure Finalize;
    class constructor Create;
    class destructor Destroy;
  end;

implementation

uses
  System.DateUtils,
  System.Math,
  JsonFlow.Objects;

{ TAsyncValidator.TTask }

constructor TAsyncValidator.TTask.Create(const ATaskId: string; const AJsonData: string;
  const ASchema: IJSONElement; APriority: TPriority;
  AProgressCallback: TProgressCallback;
  ACompletedCallback: TCompletedCallback;
  ACancelled: Boolean = False);
begin
  inherited Create;  
  FTaskId := ATaskId;
  FJsonData := AJsonData;
  FSchema := ASchema;
  FPriority := APriority;
  FProgressCallback := AProgressCallback;
  FCompletedCallback := ACompletedCallback;
  FCreatedAt := Now;
  FCancelled := ACancelled;
end;

{ TAsyncValidator.TWorkerThread }

constructor TAsyncValidator.TWorkerThread.Create(ATaskQueue: TThreadedQueue<TTask>;
  AIdleTimeout: Integer);
begin
  inherited Create(False);  
  FValidator := TJSONSchemaValidator.Create;
  FTaskQueue := ATaskQueue;
  FStatsLock := TCriticalSection.Create;
  FIdleTimeout := AIdleTimeout;  
  FillChar(FStats, SizeOf(FStats), 0);
end;

destructor TAsyncValidator.TWorkerThread.Destroy;
begin
  FValidator.Free;
  FStatsLock.Free;  
  inherited Destroy;
end;

procedure TAsyncValidator.TWorkerThread.Execute;
var
  LTask: TTask;
  LResult: TResult;
  LJsonElement: IJSONElement;
  LJsonReader: TJsonReader;
  LErrors: TList<TValidationError>;
begin
  while not Terminated do
  begin
    // Tentar obter uma tarefa da fila
    if FTaskQueue.PopItem(LTask) = wrSignaled then
    begin
      if Assigned(LTask) then
      begin
        try
          // Inicializar resultado
          LResult.TaskId := LTask.TaskId;
          LResult.Status := TStatus.Running;
          LResult.StartTime := Now;
          
          // Verificar cancelamento
          if LTask.Cancelled then
          begin
            LResult.Status := TStatus.Cancelled;
            LResult.EndTime := Now;
            LResult.ErrorMessage := 'Task was cancelled';
          end
          else
          begin
            try
              // Parsear JSON
              LJsonReader := TJsonReader.Create;
              try
                LJsonElement := LJsonReader.Read(LTask.JsonData);
              finally
                LJsonReader.Free;
              end;
              
              // Executar validação
              FValidator.ParseSchema(LTask.Schema);
              if FValidator.Validate(LJsonElement, '') then
                LErrors := TList<TValidationError>.Create
              else
                LErrors := TList<TValidationError>.Create(FValidator.GetErrors);
              
              // Preparar resultado
              LResult.Status := TStatus.Completed;
              LResult.IsValid := LErrors.Count = 0;
              LResult.Errors := LErrors;
              LResult.EndTime := Now;
              
            except
              on E: Exception do
              begin
                LResult.Status := TStatus.Error;
                LResult.IsValid := False;
                LResult.Errors := TList<TValidationError>.Create;
                LResult.EndTime := Now;
                LResult.ErrorMessage := E.Message;
              end;
            end;
          end;
          
          // Atualizar estatísticas
          _UpdateStats(LTask, LResult);
          
          // Chamar callback se definido
          if Assigned(LTask.CompletedCallback) then
          begin
            try
              LTask.CompletedCallback(LResult);
            except
              // Ignorar erros no callback
            end;
          end;
          
        finally
          LTask.Free;
        end;
      end;
    end
    else
    begin
      // Timeout - verificar se deve terminar por inatividade
      if FIdleTimeout > 0 then
        TThread.Sleep(1000)
      else
        Break;
    end;
  end;
end;

procedure TAsyncValidator.TWorkerThread._UpdateStats(const ATask: TTask;
  const AResult: TResult);
var
  LExecutionTime: Double;
begin
  FStatsLock.Enter;
  try
    Inc(FStats.TotalTasks);
    
    case AResult.Status of
      TStatus.Completed:
        begin
          Inc(FStats.CompletedTasks);
          LExecutionTime := MilliSecondsBetween(AResult.EndTime, AResult.StartTime);
          FStats.AverageExecutionTime := (FStats.AverageExecutionTime * (FStats.CompletedTasks - 1) + LExecutionTime) / FStats.CompletedTasks;
        end;
      TStatus.Error:
        Inc(FStats.FailedTasks);
      TStatus.Cancelled:
        Inc(FStats.CancelledTasks);
    end;
  finally
    FStatsLock.Leave;
  end;
end;

function TAsyncValidator.TWorkerThread.GetStats: TAsyncValidator.TStats;
begin
  FStatsLock.Enter;
  try
    Result := FStats;
  finally
    FStatsLock.Leave;
  end;
end;

{ TAsyncValidator }

constructor TAsyncValidator.Create(const AConfig: TConfig);
begin
  inherited Create;  
  FConfig := AConfig;
  FTaskQueue := TThreadedQueue<TTask>.Create(AConfig.QueueCapacity, 1000, AConfig.QueueCapacity);
  FWorkerThreads := TList<TWorkerThread>.Create;
  FRunningTasks := TDictionary<string, TTask>.Create;
  FCompletedTasks := TDictionary<string, TResult>.Create;
  FLock := TCriticalSection.Create;
  FActive := False;
  FTaskCounter := 0;
end;

destructor TAsyncValidator.Destroy;
begin
  Stop;  

  FTaskQueue.Free;
  FWorkerThreads.Free;
  FRunningTasks.Free;
  FCompletedTasks.Free;
  FLock.Free;  
  inherited Destroy;
end;

function TAsyncValidator._GenerateTaskId: string;
begin
  FLock.Enter;
  try
    Inc(FTaskCounter);
    Result := Format('TASK_%d_%d', [TThread.CurrentThread.ThreadID, FTaskCounter]);
  finally
    FLock.Leave;
  end;
end;

procedure TAsyncValidator.Start;
begin
  FLock.Enter;
  try
    if not FActive then
    begin
      FActive := True;
      _StartWorkerThreads;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TAsyncValidator.Stop;
begin
  FLock.Enter;
  try
    if FActive then
    begin
      FActive := False;
      _StopWorkerThreads;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TAsyncValidator._StartWorkerThreads;
var
  LIndex: Integer;
  LWorkerThread: TWorkerThread;
begin
  for LIndex := 0 to FConfig.MaxThreads - 1 do
  begin
    LWorkerThread := TWorkerThread.Create(FTaskQueue, FConfig.ThreadIdleTimeoutSeconds);
    FWorkerThreads.Add(LWorkerThread);
  end;
end;

procedure TAsyncValidator._StopWorkerThreads;
var
  LWorkerThread: TWorkerThread;
begin
  // Sinalizar término para todas as threads
  for LWorkerThread in FWorkerThreads do
    LWorkerThread.Terminate;
    
  // Aguardar término
  for LWorkerThread in FWorkerThreads do
  begin
    LWorkerThread.WaitFor;
    LWorkerThread.Free;
  end;
  
  FWorkerThreads.Clear;
end;

function TAsyncValidator.SubmitValidation(const AJsonData: string;
  const ASchema: IJSONElement; APriority: TPriority;
  AProgressCallback: TProgressCallback;
  ACompletedCallback: TCompletedCallback): string;
var
  LTaskId: string;
  LTask: TTask;
  LCancelled: Boolean;
begin
  if not FActive then
    raise Exception.Create('AsyncValidator is not active');
    
  LTaskId := _GenerateTaskId;
  LCancelled := False;  
  LTask := TTask.Create(LTaskId, AJsonData, ASchema, APriority,
                                   AProgressCallback, ACompletedCallback, LCancelled);
  
  FLock.Enter;
  try
    FRunningTasks.Add(LTaskId, LTask);
  finally
    FLock.Leave;
  end;  
  // Adicionar à fila
  FTaskQueue.PushItem(LTask);  
  Result := LTaskId;
end;

function TAsyncValidator.SubmitBatchValidation(const AJsonDataList: TArray<string>;
  const ASchema: IJSONElement; APriority: TPriority;
  AProgressCallback: TProgressCallback;
  ACompletedCallback: TCompletedCallback): TArray<string>;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(AJsonDataList));  
  for LIndex := 0 to High(AJsonDataList) do
  begin
    Result[LIndex] := SubmitValidation(AJsonDataList[LIndex], ASchema, APriority,
                                 AProgressCallback, ACompletedCallback);
  end;
end;

function TAsyncValidator.CancelTask(const ATaskId: string): Boolean;
var
  LTask: TTask;
begin
  Result := False;
  
  FLock.Enter;
  try
    if FRunningTasks.TryGetValue(ATaskId, LTask) then
    begin
      LTask.Cancelled := True;
      Result := True;
    end;
  finally
    FLock.Leave;
  end;
end;

function TAsyncValidator.GetTaskStatus(const ATaskId: string): TStatus;
var
  LTask: TTask;
  LResult: TResult;
begin
  FLock.Enter;
  try
    if FCompletedTasks.TryGetValue(ATaskId, LResult) then
      Result := LResult.Status
    else if FRunningTasks.TryGetValue(ATaskId, LTask) then
    begin
      if LTask.Cancelled then
        Result := TStatus.Cancelled
      else
        Result := TStatus.Running;
    end
    else
      Result := TStatus.Queued;
  finally
    FLock.Leave;
  end;
end;

function TAsyncValidator.GetTaskResult(const ATaskId: string): TResult;
begin
  FLock.Enter;
  try
    if not FCompletedTasks.TryGetValue(ATaskId, Result) then
      raise Exception.CreateFmt('Task %s not found or not completed', [ATaskId]);
  finally
    FLock.Leave;
  end;
end;

function TAsyncValidator.WaitForTask(const ATaskId: string; ATimeoutMs: Integer): Boolean;
var
  LStartTime: TDateTime;
begin
  LStartTime := Now;  
  repeat
    if GetTaskStatus(ATaskId) in [TStatus.Completed, TStatus.Cancelled, TStatus.Error] then
      Exit(True);
      
    TThread.Sleep(10);
  until (ATimeoutMs <> -1) and (MilliSecondsBetween(Now, LStartTime) >= ATimeoutMs);
  
  Result := False;
end;

function TAsyncValidator.WaitForAllTasks(ATimeoutMs: Integer): Boolean;
var
  LStartTime: TDateTime;
begin
  LStartTime := Now;
  
  repeat
    if (GetQueueSize = 0) and (FRunningTasks.Count = 0) then
      Exit(True);
      
    TThread.Sleep(50);
  until (ATimeoutMs <> -1) and (MilliSecondsBetween(Now, LStartTime) >= ATimeoutMs);
  
  Result := False;
end;

function TAsyncValidator.GetStats: TStats;
var
  LWorkerThread: TWorkerThread;
  LWorkerStats: TAsyncValidator.TStats;
begin
  FillChar(Result, SizeOf(Result), 0); 
  FLock.Enter;
  try
    Result.QueuedTasks := GetQueueSize;
    Result.RunningTasks := FRunningTasks.Count;
    Result.ActiveThreads := FWorkerThreads.Count;   
    // Agregar estatísticas de todas as threads
    for LWorkerThread in FWorkerThreads do
    begin
      LWorkerStats := LWorkerThread.GetStats;    
      Result.TotalTasks := Result.TotalTasks + LWorkerStats.TotalTasks;
      Result.CompletedTasks := Result.CompletedTasks + LWorkerStats.CompletedTasks;
      Result.FailedTasks := Result.FailedTasks + LWorkerStats.FailedTasks;
      Result.CancelledTasks := Result.CancelledTasks + LWorkerStats.CancelledTasks;
      
      if LWorkerStats.AverageExecutionTime > 0 then
        Result.AverageExecutionTime := (Result.AverageExecutionTime + LWorkerStats.AverageExecutionTime) / 2;
    end;   
    // Calcular throughput
    if Result.AverageExecutionTime > 0 then
      Result.ThroughputPerSecond := 1000 / Result.AverageExecutionTime;
  finally
    FLock.Leave;
  end;
end;

function TAsyncValidator.GetQueueSize: Integer;
begin
  Result := FTaskQueue.QueueSize;
end;

function TAsyncValidator.GetActiveThreadCount: Integer;
begin
  FLock.Enter;
  try
    Result := FWorkerThreads.Count;
  finally
    FLock.Leave;
  end;
end;


procedure TAsyncValidator.Pause;
begin
  // Implementar pausa se necessário
end;

procedure TAsyncValidator.Resume;
begin
  // Implementar retomada se necessário
end;

{ TGlobalAsyncValidator }

class constructor TGlobalAsyncValidator.Create;
begin
  FLock := TCriticalSection.Create;
end;

class destructor TGlobalAsyncValidator.Destroy;
begin
  Finalize;
  FLock.Free;
end;

class function TGlobalAsyncValidator.Instance: TAsyncValidator;
begin
  if not Assigned(FInstance) then
  begin
    FLock.Enter;
    try
      if not Assigned(FInstance) then
      begin
        // Configuração padrão
        var LConfig: TAsyncValidator.TConfig;
        LConfig.MaxThreads := TThread.ProcessorCount;
        LConfig.QueueCapacity := 1000;
        LConfig.TaskTimeoutSeconds := 300;
        LConfig.EnablePrioritization := True;
        LConfig.EnableLoadBalancing := True;
        LConfig.ThreadIdleTimeoutSeconds := 60;
        
        FInstance := TAsyncValidator.Create(LConfig);
        FInstance.Start;
      end;
    finally
      FLock.Leave;
    end;
  end;
  
  Result := FInstance;
end;

class procedure TGlobalAsyncValidator.Initialize(const AConfig: TAsyncValidator.TConfig);
begin
  FLock.Enter;
  try
    if Assigned(FInstance) then
      FInstance.Free;
      
    FInstance := TAsyncValidator.Create(AConfig);
    FInstance.Start;
  finally
    FLock.Leave;
  end;
end;

class procedure TGlobalAsyncValidator.Finalize;
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

end.