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

unit JsonFlow.Reports;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.DateUtils,
  JsonFlow.Interfaces,
  JsonFlow.Metrics
  {$IFDEF USE_STRATUM},
  Stratum.Reports
  {$ENDIF};

type
  {$IFDEF USE_STRATUM}
  // Alias para tipos do Stratum para manter compatibilidade
  TReportType = Stratum.Reports.TReportType;
  TReportFormat = Stratum.Reports.TReportFormat;
  TReportPeriod = Stratum.Reports.TReportPeriod;
  TReportConfig = Stratum.Reports.TReportConfig;
  {$ELSE}
  // Definições locais se Stratum não estiver disponível
  TReportType = (rtValidationSummary, rtPerformanceAnalysis, rtCacheAnalysis,
                 rtErrorAnalysis, rtTrendAnalysis, rtComprehensive);
  TReportFormat = (rfHTML, rfJSON, rfCSV, rfXML, rfPDF, rfText);
  TReportPeriod = record
    StartDate: TDateTime;
    EndDate: TDateTime;
    Description: string;
  end;
  TReportConfig = record
    ReportType: TReportType;
    Format: TReportFormat;
    Period: TReportPeriod;
    IncludeCharts: Boolean;
    IncludeDetails: Boolean;
    IncludeRecommendations: Boolean;
    OutputPath: string;
    Title: string;
    Author: string;
  end;
  {$ENDIF}
  
  // Fonte de dados específica para JsonFlow
  TJsonFlowDataSource = class(TInterfacedObject{$IFDEF USE_STRATUM}, IReportDataSource{$ENDIF})
  private
    FMetrics: TValidationMetrics;
  public
    constructor Create(AMetrics: TValidationMetrics);
    
    {$IFDEF USE_STRATUM}
    // IReportDataSource implementation
    function GetPerformanceData: TPerformanceData;
    function GetErrorData: TArray<TErrorData>;
    function GetTrendData: TArray<TTrendData>;
    function GetOptimizationRecommendations: TArray<TOptimizationRecommendation>;
    function GetCacheAnalysis: string;
    {$ENDIF}
  end;

  // Gerenciador principal de relatórios
  TReportManager = class
  private
    FMetrics: TValidationMetrics;
    FReportHistory: TList<string>;
    FDataSource: TJsonFlowDataSource;
  public
    constructor Create(AMetrics: TValidationMetrics);
    destructor Destroy; override;
    
    // Geração de relatórios
    function GenerateReport(const AConfig: TReportConfig): string;
    function GenerateQuickReport(AType: TReportType; AFormat: TReportFormat): string;
    
    // Relatórios predefinidos
    function GenerateDailyReport: string;
    function GenerateWeeklyReport: string;
    function GenerateMonthlyReport: string;
    function GeneratePerformanceReport: string;
    function GenerateErrorAnalysisReport: string;
    
    // Histórico
    function GetReportHistory: TArray<string>;
    procedure ClearHistory;
  end;

implementation

{ TJsonFlowDataSource }

constructor TJsonFlowDataSource.Create(AMetrics: TValidationMetrics);
begin
  inherited Create;
  FMetrics := AMetrics;
end;

{$IFDEF USE_STRATUM}
function TJsonFlowDataSource.GetPerformanceData: TPerformanceData;
begin
  // Extrair dados reais de FMetrics
  Result.TotalOperations := FMetrics.TotalValidations;
  Result.AverageTime := FMetrics.AverageValidationTime;
  Result.MinTime := FMetrics.MinValidationTime;
  Result.MaxTime := FMetrics.MaxValidationTime;
  Result.SuccessRate := FMetrics.SuccessRate;
  Result.CacheHitRate := 0.0; // Implementar se disponível em TValidationMetrics
  Result.ThroughputPerSecond := FMetrics.Throughput;
  Result.MemoryUsage := 0; // Implementar se disponível
end;

function TJsonFlowDataSource.GetErrorData: TArray<TErrorData>;
begin
  // Implementar extração de erros de FMetrics
  SetLength(Result, 0);
end;

function TJsonFlowDataSource.GetTrendData: TArray<TTrendData>;
begin
  SetLength(Result, 0);
end;

function TJsonFlowDataSource.GetOptimizationRecommendations: TArray<TOptimizationRecommendation>;
var
  LRecommendation: TOptimizationRecommendation;
begin
  // Gerar recomendações baseadas nas métricas
  SetLength(Result, 0);
  
  if FMetrics.AverageValidationTime > 100 then
  begin
    LRecommendation.Category := 'Performance';
    LRecommendation.Priority := 4;
    LRecommendation.Description := 'Tempo médio de validação alto (> 100ms)';
    LRecommendation.ExpectedImpact := 'Melhoria na latência';
    LRecommendation.ImplementationSteps := 'Verificar regras complexas ou uso de cache';
    Result := Result + [LRecommendation];
  end;
end;

function TJsonFlowDataSource.GetCacheAnalysis: string;
begin
  Result := 'Análise de cache não disponível nas métricas atuais.';
end;
{$ENDIF}

{ TReportManager }

constructor TReportManager.Create(AMetrics: TValidationMetrics);
begin
  inherited Create;
  FMetrics := AMetrics;
  FDataSource := TJsonFlowDataSource.Create(FMetrics);
  FReportHistory := TList<string>.Create;
end;

destructor TReportManager.Destroy;
begin
  FReportHistory.Free;
  FDataSource.Free; // FDataSource is a class here, managed by TReportManager if not an interface reference
  inherited Destroy;
end;

function TReportManager.GenerateReport(const AConfig: TReportConfig): string;
{$IFDEF USE_STRATUM}
var
  LGenerator: TReportGenerator;
{$ENDIF}
begin
  {$IFDEF USE_STRATUM}
  LGenerator := TReportGeneratorFactory.CreateGenerator(AConfig, FDataSource);
  try
    Result := LGenerator.Generate;
    LGenerator.SaveToFile(Result);
    
    // Adicionar ao histórico
    FReportHistory.Add(Format('%s - %s', [FormatDateTime('dd/mm/yyyy hh:nn', Now), AConfig.Title]));
  finally
    LGenerator.Free;
  end;
  {$ELSE}
  Result := 'Stratum integration is disabled. Reports are not available.';
  {$ENDIF}
end;

function TReportManager.GenerateQuickReport(AType: TReportType; AFormat: TReportFormat): string;
var
  LConfig: TReportConfig;
begin
  LConfig.ReportType := AType;
  LConfig.Format := AFormat;
  LConfig.Period.StartDate := Now - 7;
  LConfig.Period.EndDate := Now;
  LConfig.Title := 'Relatório Rápido';
  LConfig.Author := 'JsonFlow';
  LConfig.IncludeCharts := False;
  LConfig.IncludeDetails := True;
  LConfig.IncludeRecommendations := False;
  
  Result := GenerateReport(LConfig);
end;

function TReportManager.GenerateDailyReport: string;
begin
  Result := GenerateQuickReport(rtComprehensive, rfHTML);
end;

function TReportManager.GenerateWeeklyReport: string;
begin
  Result := GenerateQuickReport(rtComprehensive, rfHTML);
end;

function TReportManager.GenerateMonthlyReport: string;
begin
  Result := GenerateQuickReport(rtComprehensive, rfHTML);
end;

function TReportManager.GeneratePerformanceReport: string;
begin
  Result := GenerateQuickReport(rtPerformanceAnalysis, rfHTML);
end;

function TReportManager.GenerateErrorAnalysisReport: string;
begin
  Result := GenerateQuickReport(rtErrorAnalysis, rfHTML);
end;

function TReportManager.GetReportHistory: TArray<string>;
begin
  Result := FReportHistory.ToArray;
end;

procedure TReportManager.ClearHistory;
begin
  FReportHistory.Clear;
end;

end.
