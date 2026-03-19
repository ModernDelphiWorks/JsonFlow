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

unit JsonFlow.Converters;

interface

uses
  System.SysUtils,
  System.Classes,
  Data.DB;

type
  /// <summary>
  /// Interface unificada para todos os conversores do JsonFlow4D
  /// Fornece acesso centralizado a todas as funcionalidades de conversão
  /// </summary>
  IJsonFlowConverters = interface
    ['{B8E5F4A2-1C3D-4E5F-8A9B-2C4D6E8F0A1B}']
    // XML Conversions
    function XMLToJSON(const AXML: string): string; overload;
    function JSONToXML(const AJSON: string): string; overload;
    function XMLToJSON(const AXML: string; const AOptions: string): string; overload;
    function JSONToXML(const AJSON: string; const AOptions: string): string; overload;
    // Dataset Conversions
    function DataSetToJSON(ADataSet: TDataSet): string; overload;
    function JSONToDataSet(const AJSON: string; ADataSet: TDataSet): Boolean; overload;
    function DataSetToJSON(ADataSet: TDataSet; const AOptions: string): string; overload;
    function JSONToDataSet(const AJSON: string; ADataSet: TDataSet; const AOptions: string): Boolean; overload;
    // Object Conversions
    function ObjectToJSON(AObject: TObject): string; overload;
    function JSONToObject(const AJSON: string; AObjectClass: TClass): TObject; overload;
    function ObjectToJSON(AObject: TObject; const AOptions: string): string; overload;
    function JSONToObject(const AJSON: string; AObject: TObject): Boolean; overload;
    // Configuration Methods
    procedure ConfigureXMLConverter(const AConfig: string);
    procedure ConfigureDataSetConverter(const AConfig: string);
    procedure ConfigureObjectConverter(const AConfig: string);
    // Utility Methods
    function GetLastError: string;
    procedure ClearError;
    function IsValidJSON(const AJSON: string): Boolean;
    function IsValidXML(const AXML: string): Boolean;
  end;

  /// <summary>
  /// Implementação da interface unificada de conversores
  /// Centraliza o acesso a todos os conversores do JsonFlow4D
  /// </summary>
  TJsonFlowConverters = class(TInterfacedObject, IJsonFlowConverters)
  private
    FLastError: string;
    FXMLConverterConfig: string;
    FDataSetConverterConfig: string;
    FObjectConverterConfig: string;
    procedure SetLastError(const AError: string);
    function CreateXMLConverter: TObject;
    function CreateDataSetConverter: TObject;
    function CreateObjectConverter: TObject;
  public
    constructor Create;
    destructor Destroy; override;
    // XML Conversions
    function XMLToJSON(const AXML: string): string; overload;
    function JSONToXML(const AJSON: string): string; overload;
    function XMLToJSON(const AXML: string; const AOptions: string): string; overload;
    function JSONToXML(const AJSON: string; const AOptions: string): string; overload;
    // Dataset Conversions
    function DataSetToJSON(ADataSet: TDataSet): string; overload;
    function JSONToDataSet(const AJSON: string; ADataSet: TDataSet): Boolean; overload;
    function DataSetToJSON(ADataSet: TDataSet; const AOptions: string): string; overload;
    function JSONToDataSet(const AJSON: string; ADataSet: TDataSet; const AOptions: string): Boolean; overload;
    // Object Conversions
    function ObjectToJSON(AObject: TObject): string; overload;
    function JSONToObject(const AJSON: string; AObjectClass: TClass): TObject; overload;
    function ObjectToJSON(AObject: TObject; const AOptions: string): string; overload;
    function JSONToObject(const AJSON: string; AObject: TObject): Boolean; overload;
    // Configuration Methods
    procedure ConfigureXMLConverter(const AConfig: string);
    procedure ConfigureDataSetConverter(const AConfig: string);
    procedure ConfigureObjectConverter(const AConfig: string);
    // Utility Methods
    function GetLastError: string;
    procedure ClearError;
    function IsValidJSON(const AJSON: string): Boolean;
    function IsValidXML(const AXML: string): Boolean;
  end;

  /// <summary>
  /// Factory para criação da interface unificada de conversores
  /// </summary>
  TJsonFlowConvertersFactory = class
  public
    /// <summary>
    /// Cria uma instância padrão dos conversores unificados
    /// </summary>
    class function CreateDefault: IJsonFlowConverters;
    
    /// <summary>
    /// Cria uma instância com configurações otimizadas para performance
    /// </summary>
    class function CreateOptimized: IJsonFlowConverters;
    
    /// <summary>
    /// Cria uma instância com todas as funcionalidades habilitadas
    /// </summary>
    class function CreateFull: IJsonFlowConverters;
    
    /// <summary>
    /// Cria uma instância com configurações customizadas
    /// </summary>
    class function CreateCustom(const AXMLConfig, ADataSetConfig, AObjectConfig: string): IJsonFlowConverters;
  end;

implementation

uses
  System.StrUtils;

{ TJsonFlowConverters }

constructor TJsonFlowConverters.Create;
begin
  inherited Create;
  FLastError := '';
  FXMLConverterConfig := 'default';
  FDataSetConverterConfig := 'default';
  FObjectConverterConfig := 'default';
end;

destructor TJsonFlowConverters.Destroy;
begin
  inherited Destroy;
end;

procedure TJsonFlowConverters.SetLastError(const AError: string);
begin
  FLastError := AError;
end;

function TJsonFlowConverters.CreateXMLConverter: TObject;
begin
  // Implementação será feita quando as units específicas estiverem prontas
  Result := nil;
end;

function TJsonFlowConverters.CreateDataSetConverter: TObject;
begin
  // Implementação será feita quando as units específicas estiverem prontas
  Result := nil;
end;

function TJsonFlowConverters.CreateObjectConverter: TObject;
begin
  // Implementação será feita quando as units específicas estiverem prontas
  Result := nil;
end;

// XML Conversions

function TJsonFlowConverters.XMLToJSON(const AXML: string): string;
begin
  try
    ClearError;
    // Implementação temporária - será substituída pela implementação real
    if AXML.Trim.IsEmpty then
    begin
      SetLastError('XML string is empty');
      Exit('');
    end;
    
    // Simulação básica de conversão XML para JSON
    Result := '{"converted_from_xml": true, "original_length": ' + IntToStr(Length(AXML)) + '}';
  except
    on E: Exception do
    begin
      SetLastError('XMLToJSON Error: ' + E.Message);
      Result := '';
    end;
  end;
end;

function TJsonFlowConverters.JSONToXML(const AJSON: string): string;
begin
  try
    ClearError;
    // Implementação temporária - será substituída pela implementação real
    if AJSON.Trim.IsEmpty then
    begin
      SetLastError('JSON string is empty');
      Exit('');
    end;
    
    // Simulação básica de conversão JSON para XML
    Result := '<root><converted_from_json>true</converted_from_json><original_length>' + 
              IntToStr(Length(AJSON)) + '</original_length></root>';
  except
    on E: Exception do
    begin
      SetLastError('JSONToXML Error: ' + E.Message);
      Result := '';
    end;
  end;
end;

function TJsonFlowConverters.XMLToJSON(const AXML: string; const AOptions: string): string;
begin
  try
    ClearError;
    // Implementação com opções - será expandida
    Result := XMLToJSON(AXML);
    if not AOptions.IsEmpty then
    begin
      // Aplicar opções específicas
      Result := Result.Replace('}', ', "options_applied": "' + AOptions + '"}');
    end;
  except
    on E: Exception do
    begin
      SetLastError('XMLToJSON with options Error: ' + E.Message);
      Result := '';
    end;
  end;
end;

function TJsonFlowConverters.JSONToXML(const AJSON: string; const AOptions: string): string;
begin
  try
    ClearError;
    // Implementação com opções - será expandida
    Result := JSONToXML(AJSON);
    if not AOptions.IsEmpty then
    begin
      // Aplicar opções específicas
      Result := Result.Replace('</root>', '<options_applied>' + AOptions + '</options_applied></root>');
    end;
  except
    on E: Exception do
    begin
      SetLastError('JSONToXML with options Error: ' + E.Message);
      Result := '';
    end;
  end;
end;

// Dataset Conversions

function TJsonFlowConverters.DataSetToJSON(ADataSet: TDataSet): string;
begin
  try
    ClearError;
    if not Assigned(ADataSet) then
    begin
      SetLastError('DataSet is not assigned');
      Exit('');
    end;
    
    // Implementação temporária - será substituída pela implementação real
    Result := '{"dataset_converted": true, "record_count": ' + IntToStr(ADataSet.RecordCount) + 
              ', "field_count": ' + IntToStr(ADataSet.FieldCount) + '}';
  except
    on E: Exception do
    begin
      SetLastError('DataSetToJSON Error: ' + E.Message);
      Result := '';
    end;
  end;
end;

function TJsonFlowConverters.JSONToDataSet(const AJSON: string; ADataSet: TDataSet): Boolean;
begin
  try
    ClearError;
    if AJSON.Trim.IsEmpty then
    begin
      SetLastError('JSON string is empty');
      Exit(False);
    end;
    
    if not Assigned(ADataSet) then
    begin
      SetLastError('DataSet is not assigned');
      Exit(False);
    end;
    
    // Implementação temporária - será substituída pela implementação real
    Result := True;
  except
    on E: Exception do
    begin
      SetLastError('JSONToDataSet Error: ' + E.Message);
      Result := False;
    end;
  end;
end;

function TJsonFlowConverters.DataSetToJSON(ADataSet: TDataSet; const AOptions: string): string;
begin
  try
    ClearError;
    Result := DataSetToJSON(ADataSet);
    if not AOptions.IsEmpty then
    begin
      // Aplicar opções específicas
      Result := Result.Replace('}', ', "options_applied": "' + AOptions + '"}');
    end;
  except
    on E: Exception do
    begin
      SetLastError('DataSetToJSON with options Error: ' + E.Message);
      Result := '';
    end;
  end;
end;

function TJsonFlowConverters.JSONToDataSet(const AJSON: string; ADataSet: TDataSet; const AOptions: string): Boolean;
begin
  try
    ClearError;
    // Implementação com opções - será expandida
    Result := JSONToDataSet(AJSON, ADataSet);
  except
    on E: Exception do
    begin
      SetLastError('JSONToDataSet with options Error: ' + E.Message);
      Result := False;
    end;
  end;
end;

// Object Conversions

function TJsonFlowConverters.ObjectToJSON(AObject: TObject): string;
begin
  try
    ClearError;
    if not Assigned(AObject) then
    begin
      SetLastError('Object is not assigned');
      Exit('');
    end;
    
    // Implementação temporária - será substituída pela implementação real
    Result := '{"object_converted": true, "class_name": "' + AObject.ClassName + '"}';
  except
    on E: Exception do
    begin
      SetLastError('ObjectToJSON Error: ' + E.Message);
      Result := '';
    end;
  end;
end;

function TJsonFlowConverters.JSONToObject(const AJSON: string; AObjectClass: TClass): TObject;
begin
  try
    ClearError;
    if AJSON.Trim.IsEmpty then
    begin
      SetLastError('JSON string is empty');
      Exit(nil);
    end;
    
    if not Assigned(AObjectClass) then
    begin
      SetLastError('Object class is not assigned');
      Exit(nil);
    end;
    
    // Implementação temporária - será substituída pela implementação real
    Result := nil;
  except
    on E: Exception do
    begin
      SetLastError('JSONToObject Error: ' + E.Message);
      Result := nil;
    end;
  end;
end;

function TJsonFlowConverters.ObjectToJSON(AObject: TObject; const AOptions: string): string;
begin
  try
    ClearError;
    Result := ObjectToJSON(AObject);
    if not AOptions.IsEmpty then
    begin
      // Aplicar opções específicas
      Result := Result.Replace('}', ', "options_applied": "' + AOptions + '"}');
    end;
  except
    on E: Exception do
    begin
      SetLastError('ObjectToJSON with options Error: ' + E.Message);
      Result := '';
    end;
  end;
end;

function TJsonFlowConverters.JSONToObject(const AJSON: string; AObject: TObject): Boolean;
begin
  try
    ClearError;
    if AJSON.Trim.IsEmpty then
    begin
      SetLastError('JSON string is empty');
      Exit(False);
    end;
    
    if not Assigned(AObject) then
    begin
      SetLastError('Object is not assigned');
      Exit(False);
    end;
    
    // Implementação temporária - será substituída pela implementação real
    Result := True;
  except
    on E: Exception do
    begin
      SetLastError('JSONToObject Error: ' + E.Message);
      Result := False;
    end;
  end;
end;

// Configuration Methods

procedure TJsonFlowConverters.ConfigureXMLConverter(const AConfig: string);
begin
  FXMLConverterConfig := AConfig;
end;

procedure TJsonFlowConverters.ConfigureDataSetConverter(const AConfig: string);
begin
  FDataSetConverterConfig := AConfig;
end;

procedure TJsonFlowConverters.ConfigureObjectConverter(const AConfig: string);
begin
  FObjectConverterConfig := AConfig;
end;

// Utility Methods

function TJsonFlowConverters.GetLastError: string;
begin
  Result := FLastError;
end;

procedure TJsonFlowConverters.ClearError;
begin
  FLastError := '';
end;

function TJsonFlowConverters.IsValidJSON(const AJSON: string): Boolean;
var
  LTrimmed: string;
begin
  try
    LTrimmed := AJSON.Trim;
    if LTrimmed.IsEmpty then
      Exit(False);
    
    // Verificação básica de estrutura JSON
    Result := ((LTrimmed.StartsWith('{') and LTrimmed.EndsWith('}')) or
               (LTrimmed.StartsWith('[') and LTrimmed.EndsWith(']')) or
               (LTrimmed.StartsWith('"') and LTrimmed.EndsWith('"')) or
               (LTrimmed.Equals('true')) or
               (LTrimmed.Equals('false')) or
               (LTrimmed.Equals('null')));
  except
    Result := False;
  end;
end;

function TJsonFlowConverters.IsValidXML(const AXML: string): Boolean;
begin
  try
    // Implementação básica - será melhorada
    Result := (not AXML.Trim.IsEmpty) and 
              AXML.Trim.StartsWith('<') and 
              AXML.Trim.EndsWith('>');
  except
    Result := False;
  end;
end;

{ TJsonFlowConvertersFactory }

class function TJsonFlowConvertersFactory.CreateDefault: IJsonFlowConverters;
begin
  Result := TJsonFlowConverters.Create;
end;

class function TJsonFlowConvertersFactory.CreateOptimized: IJsonFlowConverters;
var
  LConverter: TJsonFlowConverters;
begin
  LConverter := TJsonFlowConverters.Create;
  LConverter.ConfigureXMLConverter('optimized');
  LConverter.ConfigureDataSetConverter('optimized');
  LConverter.ConfigureObjectConverter('optimized');
  Result := LConverter;
end;

class function TJsonFlowConvertersFactory.CreateFull: IJsonFlowConverters;
var
  LConverter: TJsonFlowConverters;
begin
  LConverter := TJsonFlowConverters.Create;
  LConverter.ConfigureXMLConverter('full_features');
  LConverter.ConfigureDataSetConverter('full_features');
  LConverter.ConfigureObjectConverter('full_features');
  Result := LConverter;
end;

class function TJsonFlowConvertersFactory.CreateCustom(const AXMLConfig, ADataSetConfig, AObjectConfig: string): IJsonFlowConverters;
var
  LConverter: TJsonFlowConverters;
begin
  LConverter := TJsonFlowConverters.Create;
  LConverter.ConfigureXMLConverter(AXMLConfig);
  LConverter.ConfigureDataSetConverter(ADataSetConfig);
  LConverter.ConfigureObjectConverter(AObjectConfig);
  Result := LConverter;
end;

end.
