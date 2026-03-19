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

unit JsonFlow.Converter.Dataset;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Variants,
  System.Generics.Collections,
  System.NetEncoding,
  Data.DB,
  JsonFlow.Navigator,
  JsonFlow.Interfaces,
  JsonFlow.Composer,
  JsonFlow.Objects,
  JsonFlow.Arrays,
  JsonFlow.Value;

type
  /// <summary>
  /// Estratégia para tratamento de valores nulos
  /// </summary>
  TNullValueHandling = (
    nvhInclude,     // Incluir como null
    nvhExclude,     // Excluir do JSON
    nvhEmptyString  // Converter para string vazia
  );

  /// <summary>
  /// Formato de nomes de campos
  /// </summary>
  TFieldNameCase = (
    fncOriginal,    // Manter original
    fncLowerCase,   // Converter para minúsculo
    fncUpperCase,   // Converter para maiúsculo
    fncCamelCase,   // Converter para camelCase
    fncPascalCase   // Converter para PascalCase
  );

  /// <summary>
  /// Opções para conversão Dataset ? JSON
  /// </summary>
  TDatasetToJSONOptions = record
    IncludeMetadata: Boolean;
    IncludeFieldDefs: Boolean;
    DateTimeFormat: string;
    FloatFormat: string;
    NullValueHandling: TNullValueHandling;
    FieldNameCase: TFieldNameCase;
    IncludeEmptyArrays: Boolean;
    MaxRecords: Integer; // 0 = sem limite
    BufferSize: Integer; // Para processamento em lotes
    
    class function Default: TDatasetToJSONOptions; static;
  end;

  /// <summary>
  /// Mapeamento customizado de campo
  /// </summary>
  TFieldMapping = record
    FieldName: string;
    JSONPath: string;
    ConverterClass: TClass;
    
    constructor Create(const AFieldName, AJSONPath: string; AConverterClass: TClass = nil);
  end;

  /// <summary>
  /// Interface para conversores de campo customizados
  /// </summary>
  IFieldConverter = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    function FieldToJSON(AField: TField): IJSONElement;
    procedure JSONToField(AElement: IJSONElement; AField: TField);
  end;

  /// <summary>
  /// Conversor principal Dataset ? JSON
  /// </summary>
  TJSONDatasetConverter = class
  private
    FComposer: TJSONComposer;
    FOptions: TDatasetToJSONOptions;
    FFieldMappings: TDictionary<string, TFieldMapping>;
    FCustomConverters: TDictionary<string, IFieldConverter>;
    FOnProgress: TProc<Integer, Integer>; // Current, Total
  private
    function FormatFieldName(const AFieldName: string): string;
    function ConvertFieldValue(AField: TField): IJSONElement;
    procedure SetFieldValue(AField: TField; AElement: IJSONElement);
    function GetFieldConverter(const AFieldName: string): IFieldConverter;
    procedure AddMetadata(AComposer: TJSONComposer; ADataset: TDataset);
    procedure AddFieldDefs(AComposer: TJSONComposer; ADataset: TDataset);
  public
    constructor Create(const AOptions: TDatasetToJSONOptions);
    destructor Destroy; override;
    
    // Conversão Dataset ? JSON
    function DatasetToJSON(ADataset: TDataset): string;
    function DatasetToJSONArray(ADataset: TDataset): IJSONArray;
    function RecordToJSON(ADataset: TDataset): string;
    function RecordToJSONObject(ADataset: TDataset): IJSONObject;
    
    // Conversão JSON ? Dataset
    procedure JSONToDataset(const AJSON: string; ADataset: TDataset; const AClearFirst: Boolean = True);
    procedure JSONArrayToDataset(AArray: IJSONArray; ADataset: TDataset; const AClearFirst: Boolean = True);
    procedure JSONObjectToRecord(AObject: IJSONObject; ADataset: TDataset);
    
    // Operações específicas
    function GetChangedRecordsAsJSON(ADataset: TDataset): string;
    procedure ApplyJSONChanges(const AJSON: string; ADataset: TDataset);
    function CompareRecordWithJSON(ADataset: TDataset; const AJSON: string): TArray<string>;
    
    // Processamento assíncrono/streaming
    procedure StreamDatasetToJSON(ADataset: TDataset; AStream: TStream);
    procedure StreamJSONToDataset(AStream: TStream; ADataset: TDataset);
    
    // Mapeamentos customizados
    procedure AddFieldMapping(const AFieldName, AJSONPath: string; AConverterClass: TClass = nil);
    procedure RemoveFieldMapping(const AFieldName: string);
    procedure ClearFieldMappings;
    
    // Conversores customizados
    procedure AddCustomConverter(const AFieldName: string; AConverter: IFieldConverter);
    procedure RemoveCustomConverter(const AFieldName: string);
    
    // Propriedades
    property Options: TDatasetToJSONOptions read FOptions write FOptions;
    property OnProgress: TProc<Integer, Integer> read FOnProgress write FOnProgress;
  end;

  /// <summary>
  /// Conversor para campos Blob ? Base64
  /// </summary>
  TBlobToBase64Converter = class(TInterfacedObject, IFieldConverter)
  public
    function FieldToJSON(AField: TField): IJSONElement;
    procedure JSONToField(AElement: IJSONElement; AField: TField);
  end;

  /// <summary>
  /// Conversor para campos DateTime customizado
  /// </summary>
  TCustomDateTimeConverter = class(TInterfacedObject, IFieldConverter)
  private
    FFormat: string;
  public
    constructor Create(const AFormat: string);
    function FieldToJSON(AField: TField): IJSONElement;
    procedure JSONToField(AElement: IJSONElement; AField: TField);
  end;

  /// <summary>
  /// Factory para criação de conversores
  /// </summary>
  TDatasetConverterFactory = class
  public
    class function CreateConverter(const AOptions: TDatasetToJSONOptions): TJSONDatasetConverter;
    class function CreateWithDefaults: TJSONDatasetConverter;
    class function CreateForFireDAC: TJSONDatasetConverter;
    class function CreateForClientDataSet: TJSONDatasetConverter;
  end;

implementation

uses
  System.StrUtils,
  System.DateUtils;

{ TDatasetToJSONOptions }

class function TDatasetToJSONOptions.Default: TDatasetToJSONOptions;
begin
  Result.IncludeMetadata := False;
  Result.IncludeFieldDefs := False;
  Result.DateTimeFormat := 'yyyy-mm-dd"T"hh:nn:ss.zzz"Z"';
  Result.FloatFormat := '0.##########';
  Result.NullValueHandling := nvhInclude;
  Result.FieldNameCase := fncOriginal;
  Result.IncludeEmptyArrays := True;
  Result.MaxRecords := 0; // Sem limite
  Result.BufferSize := 1000;
end;

{ TFieldMapping }

constructor TFieldMapping.Create(const AFieldName, AJSONPath: string; AConverterClass: TClass);
begin
  FieldName := AFieldName;
  JSONPath := AJSONPath;
  ConverterClass := AConverterClass;
end;

{ TJSONDatasetConverter }

constructor TJSONDatasetConverter.Create(const AOptions: TDatasetToJSONOptions);
begin
  inherited Create;
  FComposer := TJSONComposer.Create;
  FOptions := AOptions;
  FFieldMappings := TDictionary<string, TFieldMapping>.Create;
  FCustomConverters := TDictionary<string, IFieldConverter>.Create;
end;

destructor TJSONDatasetConverter.Destroy;
begin
  FCustomConverters.Free;
  FFieldMappings.Free;
  FComposer.Free;
  inherited;
end;

function TJSONDatasetConverter.FormatFieldName(const AFieldName: string): string;
begin
  case FOptions.FieldNameCase of
    fncOriginal: Result := AFieldName;
    fncLowerCase: Result := LowerCase(AFieldName);
    fncUpperCase: Result := UpperCase(AFieldName);
    fncCamelCase: 
      begin
        Result := LowerCase(AFieldName);
        // Implementar conversão para camelCase
      end;
    fncPascalCase:
      begin
        Result := AFieldName;
        if Length(Result) > 0 then
          Result[1] := UpCase(Result[1]);
      end;
  else
    Result := AFieldName;
  end;
end;

function TJSONDatasetConverter.ConvertFieldValue(AField: TField): IJSONElement;
var
  LConverter: IFieldConverter;
begin
  // Verificar conversor customizado
  LConverter := GetFieldConverter(AField.FieldName);
  if Assigned(LConverter) then
  begin
    Result := LConverter.FieldToJSON(AField);
    Exit;
  end;
  
  // Tratar valores nulos
  if AField.IsNull then
  begin
    case FOptions.NullValueHandling of
      nvhInclude: Result := TJSONValueNull.Create;
      nvhExclude: Result := nil;
      nvhEmptyString: Result := TJSONValueString.Create('');
    else
      Result := TJSONValueNull.Create;
    end;
    Exit;
  end;
  
  // Conversão por tipo de campo
  case AField.DataType of
    ftString, ftWideString, ftMemo, ftWideMemo, ftFmtMemo:
      Result := TJSONValueString.Create(AField.AsString);
      
    ftSmallint, ftInteger, ftWord, ftAutoInc, ftLargeint:
      Result := TJSONValueInteger.Create(AField.AsLargeInt);
      
    ftBoolean:
      Result := TJSONValueBoolean.Create(AField.AsBoolean);
      
    ftFloat, ftCurrency, ftBCD, ftFMTBcd:
      Result := TJSONValueFloat.Create(AField.AsFloat);
      
    ftDate, ftTime, ftDateTime, ftTimeStamp:
      Result := TJSONValueDateTime.Create(AField.AsDateTime);
      
    ftBlob, ftGraphic, ftTypedBinary:
      begin
        // Converter para Base64
        var LStream := TMemoryStream.Create;
        try
          TBlobField(AField).SaveToStream(LStream);
          LStream.Position := 0;
          var LBytes: TBytes;
          SetLength(LBytes, LStream.Size);
          LStream.ReadBuffer(LBytes, LStream.Size);
          Result := TJSONValueString.Create(TNetEncoding.Base64.EncodeBytesToString(LBytes));
        finally
          LStream.Free;
        end;
      end;
      
    ftDataSet:
      begin
        // Converter dataset aninhado
        var LNestedDataset := TDataSetField(AField).NestedDataSet;
        if Assigned(LNestedDataset) then
          Result := DatasetToJSONArray(LNestedDataset)
        else
          Result := TJSONValueNull.Create;
      end;
      
    ftArray:
      begin
        // Implementar conversão de arrays
        Result := TJSONArray.Create;
        // TODO: Implementar conversão específica para arrays
      end;
      
  else
    // Tipo não suportado, converter para string
    Result := TJSONValueString.Create(AField.AsString);
  end;
end;

procedure TJSONDatasetConverter.SetFieldValue(AField: TField; AElement: IJSONElement);
var
  LConverter: IFieldConverter;
  LValue: IJSONValue;
begin
  // Verificar conversor customizado
  LConverter := GetFieldConverter(AField.FieldName);
  if Assigned(LConverter) then
  begin
    LConverter.JSONToField(AElement, AField);
    Exit;
  end;
  
  // Tratar null
  if not Assigned(AElement) or (AElement is TJSONValueNull) then
  begin
    AField.Clear;
    Exit;
  end;
  
  if not Supports(AElement, IJSONValue, LValue) then
    Exit;
    
  // Conversão por tipo de campo
  case AField.DataType of
    ftString, ftWideString, ftMemo, ftWideMemo, ftFmtMemo:
      AField.AsString := LValue.AsString;
      
    ftSmallint, ftInteger, ftWord, ftAutoInc, ftLargeint:
      AField.AsLargeInt := LValue.AsInteger;
      
    ftBoolean:
      AField.AsBoolean := LValue.AsBoolean;
      
    ftFloat, ftCurrency, ftBCD, ftFMTBcd:
      AField.AsFloat := LValue.AsFloat;
      
//    ftDate, ftTime, ftDateTime, ftTimeStamp:
//      AField.AsDateTime := LValue.AsDateTime;

    ftBlob, ftGraphic, ftTypedBinary:
      begin
        // Decodificar Base64
        var LBytes := TNetEncoding.Base64.DecodeStringToBytes(LValue.AsString);
        var LStream := TMemoryStream.Create;
        try
          LStream.WriteBuffer(LBytes, Length(LBytes));
          LStream.Position := 0;
          TBlobField(AField).LoadFromStream(LStream);
        finally
          LStream.Free;
        end;
      end;
      
  else
    // Tipo não suportado, definir como string
    AField.AsString := LValue.AsString;
  end;
end;

function TJSONDatasetConverter.GetFieldConverter(const AFieldName: string): IFieldConverter;
begin
  if FCustomConverters.ContainsKey(AFieldName) then
    Result := FCustomConverters[AFieldName]
  else
    Result := nil;
end;

procedure TJSONDatasetConverter.AddMetadata(AComposer: TJSONComposer; ADataset: TDataset);
begin
  AComposer.BeginObject('metadata')
    .Add('recordCount', ADataset.RecordCount)
    .Add('fieldCount', ADataset.FieldCount)
    .Add('active', ADataset.Active)
    .Add('eof', ADataset.Eof)
    .Add('bof', ADataset.Bof)
    .Add('modified', ADataset.Modified)
    .Add('state', Ord(ADataset.State))
  .EndObject;
end;

procedure TJSONDatasetConverter.AddFieldDefs(AComposer: TJSONComposer; ADataset: TDataset);
var
  I: Integer;
begin
  AComposer.BeginArray('fieldDefs');
  for I := 0 to ADataset.FieldDefs.Count - 1 do
  begin
    AComposer.BeginObject
      .Add('name', ADataset.FieldDefs[I].Name)
      .Add('dataType', Ord(ADataset.FieldDefs[I].DataType))
      .Add('size', ADataset.FieldDefs[I].Size)
      .Add('required', ADataset.FieldDefs[I].Required)
    .EndObject;
  end;
  AComposer.EndArray;
end;

function TJSONDatasetConverter.DatasetToJSON(ADataset: TDataset): string;
var
  LArray: IJSONArray;
begin
  FComposer.Clear;
  
  if FOptions.IncludeMetadata then
    AddMetadata(FComposer, ADataset);
    
  if FOptions.IncludeFieldDefs then
    AddFieldDefs(FComposer, ADataset);
    
  LArray := DatasetToJSONArray(ADataset);
  FComposer.Add('data', LArray);
  
//  Result := FComposer.GetJSONString;
end;

function TJSONDatasetConverter.DatasetToJSONArray(ADataset: TDataset): IJSONArray;
var
  LArray: IJSONArray;
  LRecordCount: Integer;
begin
  LArray := TJSONArray.Create;
  LRecordCount := 0;
  
  ADataset.First;
  while not ADataset.Eof do
  begin
    LArray.Add(RecordToJSONObject(ADataset));
    Inc(LRecordCount);
    
    // Verificar limite de registros
    if (FOptions.MaxRecords > 0) and (LRecordCount >= FOptions.MaxRecords) then
      Break;
      
    // Callback de progresso
    if Assigned(FOnProgress) and (LRecordCount mod FOptions.BufferSize = 0) then
      FOnProgress(LRecordCount, ADataset.RecordCount);
      
    ADataset.Next;
  end;
  
  Result := LArray;
end;

function TJSONDatasetConverter.RecordToJSON(ADataset: TDataset): string;
var
  LObject: IJSONObject;
begin
  LObject := RecordToJSONObject(ADataset);
  Result := LObject.AsJSON;
end;

function TJSONDatasetConverter.RecordToJSONObject(ADataset: TDataset): IJSONObject;
var
  LObject: IJSONObject;
  I: Integer;
  LField: TField;
  LFieldName: string;
  LElement: IJSONElement;
begin
  LObject := TJSONObject.Create;
  
  for I := 0 to ADataset.FieldCount - 1 do
  begin
    LField := ADataset.Fields[I];
    LFieldName := FormatFieldName(LField.FieldName);
    LElement := ConvertFieldValue(LField);
    
    if Assigned(LElement) then
      LObject.Add(LFieldName, LElement);
  end;
  
  Result := LObject;
end;

procedure TJSONDatasetConverter.JSONToDataset(const AJSON: string; ADataset: TDataset; const AClearFirst: Boolean);
var
  LComposer: TJSONComposer;
  LNavigator: TJSONNavigator;
  LArray: IJSONArray;
begin
  LComposer := TJSONComposer.Create;
  try
    LComposer.LoadJSON(AJSON);
//    LNavigator := LComposer.Navigator;

//    if LNavigator.HasPath('data') then
//    begin
//      if Supports(LNavigator.GetValue('data'), IJSONArray, LArray) then
//        JSONArrayToDataset(LArray, ADataset, AClearFirst);
//    end
//    else
//    begin
//      // JSON é um array direto
//      if Supports(LComposer.GetJSONElement, IJSONArray, LArray) then
//        JSONArrayToDataset(LArray, ADataset, AClearFirst);
//    end;
  finally
    LComposer.Free;
  end;
end;

procedure TJSONDatasetConverter.JSONArrayToDataset(AArray: IJSONArray; ADataset: TDataset; const AClearFirst: Boolean);
var
  I: Integer;
  LObject: IJSONObject;
begin
  if AClearFirst then
  begin
    ADataset.Close;
    ADataset.Open;
//    ADataset.EmptyDataSet;
  end;
  
  for I := 0 to AArray.Count - 1 do
  begin
    if Supports(AArray.GetItem(I), IJSONObject, LObject) then
    begin
      ADataset.Append;
      try
        JSONObjectToRecord(LObject, ADataset);
        ADataset.Post;
      except
        ADataset.Cancel;
        raise;
      end;
    end;
  end;
end;

procedure TJSONDatasetConverter.JSONObjectToRecord(AObject: IJSONObject; ADataset: TDataset);
var
  I: Integer;
  LField: TField;
  LFieldName: string;
  LElement: IJSONElement;
begin
  for I := 0 to ADataset.FieldCount - 1 do
  begin
    LField := ADataset.Fields[I];
    LFieldName := FormatFieldName(LField.FieldName);
    
    if AObject.ContainsKey(LFieldName) then
    begin
      LElement := AObject.GetValue(LFieldName);
      SetFieldValue(LField, LElement);
    end;
  end;
end;

function TJSONDatasetConverter.GetChangedRecordsAsJSON(ADataset: TDataset): string;
var
  LArray: IJSONArray;
  LBookmark: TBookmark;
begin
  LArray := TJSONArray.Create;
  LBookmark := ADataset.GetBookmark;
  try
    ADataset.First;
    while not ADataset.Eof do
    begin
      if ADataset.UpdateStatus in [usModified, usInserted] then
        LArray.Add(RecordToJSONObject(ADataset));
      ADataset.Next;
    end;
  finally
    if ADataset.BookmarkValid(LBookmark) then
      ADataset.GotoBookmark(LBookmark);
    ADataset.FreeBookmark(LBookmark);
  end;
  
  Result := LArray.AsJSON;
end;

procedure TJSONDatasetConverter.ApplyJSONChanges(const AJSON: string; ADataset: TDataset);
begin
  // Implementar aplicação de mudanças
  JSONToDataset(AJSON, ADataset, False);
end;

function TJSONDatasetConverter.CompareRecordWithJSON(ADataset: TDataset; const AJSON: string): TArray<string>;
var
  LComposer: TJSONComposer;
  LObject: IJSONObject;
  LChangedFields: TList<string>;
  I: Integer;
  LField: TField;
  LFieldName: string;
  LElement: IJSONElement;
  LCurrentValue, LJSONValue: Variant;
begin
  LChangedFields := TList<string>.Create;
  LComposer := TJSONComposer.Create;
  try
    LComposer.LoadJSON(AJSON);
//    if Supports(LComposer.GetJSONElement, IJSONObject, LObject) then
//    begin
//      for I := 0 to ADataset.FieldCount - 1 do
//      begin
//        LField := ADataset.Fields[I];
//        LFieldName := FormatFieldName(LField.FieldName);
//
//        if LObject.ContainsKey(LFieldName) then
//        begin
//          LElement := LObject.GetValue(LFieldName);
//          LCurrentValue := LField.Value;
//
//          if Supports(LElement, IJSONValue) then
//          begin
//            case LField.DataType of
//              ftString, ftWideString: LJSONValue := IJSONValue(LElement).AsString;
//              ftInteger, ftSmallint: LJSONValue := IJSONValue(LElement).AsInt64;
//              ftFloat: LJSONValue := IJSONValue(LElement).AsFloat;
//              ftBoolean: LJSONValue := IJSONValue(LElement).AsBoolean;
//              ftDateTime: LJSONValue := IJSONValue(LElement).AsDateTime;
//            else
//              LJSONValue := IJSONValue(LElement).AsString;
//            end;
//
//            if LCurrentValue <> LJSONValue then
//              LChangedFields.Add(LFieldName);
//          end;
//        end;
//      end;
//    end;

    Result := LChangedFields.ToArray;
  finally
    LComposer.Free;
    LChangedFields.Free;
  end;
end;

procedure TJSONDatasetConverter.StreamDatasetToJSON(ADataset: TDataset; AStream: TStream);
var
  LWriter: TStreamWriter;
  LRecordCount: Integer;
begin
  LWriter := TStreamWriter.Create(AStream);
  try
    LWriter.Write('[');
    LRecordCount := 0;
    
    ADataset.First;
    while not ADataset.Eof do
    begin
      if LRecordCount > 0 then
        LWriter.Write(',');
        
      LWriter.Write(RecordToJSON(ADataset));
      Inc(LRecordCount);
      
      if Assigned(FOnProgress) and (LRecordCount mod FOptions.BufferSize = 0) then
        FOnProgress(LRecordCount, ADataset.RecordCount);
        
      ADataset.Next;
    end;
    
    LWriter.Write(']');
  finally
    LWriter.Free;
  end;
end;

procedure TJSONDatasetConverter.StreamJSONToDataset(AStream: TStream; ADataset: TDataset);
var
  LReader: TStreamReader;
  LJSON: string;
begin
  LReader := TStreamReader.Create(AStream);
  try
    LJSON := LReader.ReadToEnd;
    JSONToDataset(LJSON, ADataset);
  finally
    LReader.Free;
  end;
end;

procedure TJSONDatasetConverter.AddFieldMapping(const AFieldName, AJSONPath: string; AConverterClass: TClass);
begin
  FFieldMappings.AddOrSetValue(AFieldName, TFieldMapping.Create(AFieldName, AJSONPath, AConverterClass));
end;

procedure TJSONDatasetConverter.RemoveFieldMapping(const AFieldName: string);
begin
  FFieldMappings.Remove(AFieldName);
end;

procedure TJSONDatasetConverter.ClearFieldMappings;
begin
  FFieldMappings.Clear;
end;

procedure TJSONDatasetConverter.AddCustomConverter(const AFieldName: string; AConverter: IFieldConverter);
begin
  FCustomConverters.AddOrSetValue(AFieldName, AConverter);
end;

procedure TJSONDatasetConverter.RemoveCustomConverter(const AFieldName: string);
begin
  FCustomConverters.Remove(AFieldName);
end;

{ TBlobToBase64Converter }

function TBlobToBase64Converter.FieldToJSON(AField: TField): IJSONElement;
var
  LStream: TMemoryStream;
  LBytes: TBytes;
begin
  if AField.IsNull then
  begin
    Result := TJSONValueNull.Create;
    Exit;
  end;
  
  LStream := TMemoryStream.Create;
  try
    TBlobField(AField).SaveToStream(LStream);
    LStream.Position := 0;
    SetLength(LBytes, LStream.Size);
    LStream.ReadBuffer(LBytes, LStream.Size);
    Result := TJSONValueString.Create(TNetEncoding.Base64.EncodeBytesToString(LBytes));
  finally
    LStream.Free;
  end;
end;

procedure TBlobToBase64Converter.JSONToField(AElement: IJSONElement; AField: TField);
var
  LValue: IJSONValue;
  LBytes: TBytes;
  LStream: TMemoryStream;
begin
  if not Assigned(AElement) or (AElement is TJSONValueNull) then
  begin
    AField.Clear;
    Exit;
  end;
  
  if Supports(AElement, IJSONValue, LValue) then
  begin
    LBytes := TNetEncoding.Base64.DecodeStringToBytes(LValue.AsString);
    LStream := TMemoryStream.Create;
    try
      LStream.WriteBuffer(LBytes, Length(LBytes));
      LStream.Position := 0;
      TBlobField(AField).LoadFromStream(LStream);
    finally
      LStream.Free;
    end;
  end;
end;

{ TCustomDateTimeConverter }

constructor TCustomDateTimeConverter.Create(const AFormat: string);
begin
  inherited Create;
  FFormat := AFormat;
end;

function TCustomDateTimeConverter.FieldToJSON(AField: TField): IJSONElement;
begin
  if AField.IsNull then
    Result := TJSONValueNull.Create
  else
    Result := TJSONValueString.Create(FormatDateTime(FFormat, AField.AsDateTime));
end;

procedure TCustomDateTimeConverter.JSONToField(AElement: IJSONElement; AField: TField);
var
  LValue: IJSONValue;
begin
  if not Assigned(AElement) or (AElement is TJSONValueNull) then
  begin
    AField.Clear;
    Exit;
  end;
  
  if Supports(AElement, IJSONValue, LValue) then
  begin
    try
      AField.AsDateTime := StrToDateTime(LValue.AsString);
    except
      // Se falhar, tentar ISO8601
      AField.AsDateTime := ISO8601ToDate(LValue.AsString);
    end;
  end;
end;

{ TDatasetConverterFactory }

class function TDatasetConverterFactory.CreateConverter(const AOptions: TDatasetToJSONOptions): TJSONDatasetConverter;
begin
  Result := TJSONDatasetConverter.Create(AOptions);
end;

class function TDatasetConverterFactory.CreateWithDefaults: TJSONDatasetConverter;
begin
  Result := TJSONDatasetConverter.Create(TDatasetToJSONOptions.Default);
end;

class function TDatasetConverterFactory.CreateForFireDAC: TJSONDatasetConverter;
var
  LOptions: TDatasetToJSONOptions;
begin
  LOptions := TDatasetToJSONOptions.Default;
  LOptions.IncludeMetadata := True;
  LOptions.BufferSize := 5000; // FireDAC otimizado para lotes maiores
  Result := TJSONDatasetConverter.Create(LOptions);
end;

class function TDatasetConverterFactory.CreateForClientDataSet: TJSONDatasetConverter;
var
  LOptions: TDatasetToJSONOptions;
begin
  LOptions := TDatasetToJSONOptions.Default;
  LOptions.IncludeFieldDefs := True;
  LOptions.BufferSize := 1000;
  Result := TJSONDatasetConverter.Create(LOptions);
end;

end.
