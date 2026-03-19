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

unit JsonFlow.Serializer.Attributes;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Rtti,
  System.TypInfo,
  JsonFlow.Interfaces;

type
  /// <summary>
  /// Atributo base para controle de serialização
  /// </summary>
  JSONSerializationAttribute = class(TCustomAttribute)
  end;

  /// <summary>
  /// Ignora a propriedade durante a serialização
  /// </summary>
  JSONIgnoreAttribute = class(JSONSerializationAttribute)
  end;

  /// <summary>
  /// Define um nome customizado para a propriedade no JSON
  /// </summary>
  JSONNameAttribute = class(JSONSerializationAttribute)
  private
    FName: string;
  public
    constructor Create(const AName: string);
    property Name: string read FName;
  end;

  /// <summary>
  /// Controla se a propriedade deve ser incluída quando é null/vazia
  /// </summary>
  JSONIncludeAttribute = class(JSONSerializationAttribute)
  private
    FIncludeNull: Boolean;
    FIncludeEmpty: Boolean;
  public
    constructor Create(const AIncludeNull: Boolean = True; const AIncludeEmpty: Boolean = True);
    property IncludeNull: Boolean read FIncludeNull;
    property IncludeEmpty: Boolean read FIncludeEmpty;
  end;

  /// <summary>
  /// Define formato customizado para DateTime
  /// </summary>
  JSONDateTimeFormatAttribute = class(JSONSerializationAttribute)
  private
    FFormat: string;
    FUseISO8601: Boolean;
  public
    constructor Create(const AFormat: string); overload;
    constructor Create(const AUseISO8601: Boolean); overload;
    property Format: string read FFormat;
    property UseISO8601: Boolean read FUseISO8601;
  end;

  /// <summary>
  /// Define formato customizado para números Float
  /// </summary>
  JSONFloatFormatAttribute = class(JSONSerializationAttribute)
  private
    FDecimalPlaces: Integer;
    FUseDecimalSeparator: Boolean;
  public
    constructor Create(const ADecimalPlaces: Integer; const AUseDecimalSeparator: Boolean = True);
    property DecimalPlaces: Integer read FDecimalPlaces;
    property UseDecimalSeparator: Boolean read FUseDecimalSeparator;
  end;

  /// <summary>
  /// Interface para conversores customizados
  /// </summary>
  IJSONPropertyConverter = interface
    ['{B8F5E5C1-8B4A-4D5E-9F2A-1C3D4E5F6A7B}']
    function ToJSON(const AValue: TValue; const AProperty: TRttiProperty): IJSONElement;
    function FromJSON(const AElement: IJSONElement; const AProperty: TRttiProperty): TValue;
  end;

  /// <summary>
  /// Especifica um conversor customizado para a propriedade
  /// </summary>
  JSONConverterAttribute = class(JSONSerializationAttribute)
  private
    FConverterClass: TClass;
  public
    constructor Create(AConverterClass: TClass);
    function CreateConverter: IJSONPropertyConverter;
    property ConverterClass: TClass read FConverterClass;
  end;

  /// <summary>
  /// Define ordem de serialização das propriedades
  /// </summary>
  JSONOrderAttribute = class(JSONSerializationAttribute)
  private
    FOrder: Integer;
  public
    constructor Create(const AOrder: Integer);
    property Order: Integer read FOrder;
  end;

  /// <summary>
  /// Controla se arrays/listas vazias devem ser incluídas
  /// </summary>
  JSONArrayAttribute = class(JSONSerializationAttribute)
  private
    FIncludeEmpty: Boolean;
    FItemName: string;
  public
    constructor Create(const AIncludeEmpty: Boolean = True; const AItemName: string = '');
    property IncludeEmpty: Boolean read FIncludeEmpty;
    property ItemName: string read FItemName;
  end;

  /// <summary>
  /// Marca propriedade como obrigatória (para validação)
  /// </summary>
  JSONRequiredAttribute = class(JSONSerializationAttribute)
  end;

  /// <summary>
  /// Define validação customizada para a propriedade
  /// </summary>
  JSONValidationAttribute = class(JSONSerializationAttribute)
  private
    FMinLength: Integer;
    FMaxLength: Integer;
    FPattern: string;
  public
    constructor Create(const AMinLength: Integer = -1; const AMaxLength: Integer = -1; const APattern: string = '');
    property MinLength: Integer read FMinLength;
    property MaxLength: Integer read FMaxLength;
    property Pattern: string read FPattern;
  end;

  /// <summary>
  /// Helper para trabalhar com atributos de serialização
  /// </summary>
  TJSONAttributeHelper = class
  public
    /// <summary>
    /// Verifica se a propriedade deve ser ignorada
    /// </summary>
    class function ShouldIgnoreProperty(const AProperty: TRttiProperty): Boolean;
    
    /// <summary>
    /// Obtém o nome JSON da propriedade
    /// </summary>
    class function GetJSONPropertyName(const AProperty: TRttiProperty): string;
    
    /// <summary>
    /// Verifica se deve incluir valor null/vazio
    /// </summary>
    class function ShouldIncludeValue(const AProperty: TRttiProperty; const AValue: TValue): Boolean;
    
    /// <summary>
    /// Obtém formato de DateTime customizado
    /// </summary>
    class function GetDateTimeFormat(const AProperty: TRttiProperty; out AFormat: string; out AUseISO8601: Boolean): Boolean;
    
    /// <summary>
    /// Obtém formato de Float customizado
    /// </summary>
    class function GetFloatFormat(const AProperty: TRttiProperty; out ADecimalPlaces: Integer; out AUseDecimalSeparator: Boolean): Boolean;
    
    /// <summary>
    /// Obtém conversor customizado
    /// </summary>
    class function GetCustomConverter(const AProperty: TRttiProperty): IJSONPropertyConverter;
    
    /// <summary>
    /// Obtém ordem de serialização
    /// </summary>
    class function GetSerializationOrder(const AProperty: TRttiProperty): Integer;
    
    /// <summary>
    /// Verifica se propriedade é obrigatória
    /// </summary>
    class function IsRequiredProperty(const AProperty: TRttiProperty): Boolean;
    
    /// <summary>
    /// Obtém configurações de array
    /// </summary>
    class function GetArraySettings(const AProperty: TRttiProperty; out AIncludeEmpty: Boolean; out AItemName: string): Boolean;
  end;

implementation

{ JSONNameAttribute }

constructor JSONNameAttribute.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
end;

{ JSONIncludeAttribute }

constructor JSONIncludeAttribute.Create(const AIncludeNull, AIncludeEmpty: Boolean);
begin
  inherited Create;
  FIncludeNull := AIncludeNull;
  FIncludeEmpty := AIncludeEmpty;
end;

{ JSONDateTimeFormatAttribute }

constructor JSONDateTimeFormatAttribute.Create(const AFormat: string);
begin
  inherited Create;
  FFormat := AFormat;
  FUseISO8601 := False;
end;

constructor JSONDateTimeFormatAttribute.Create(const AUseISO8601: Boolean);
begin
  inherited Create;
  FUseISO8601 := AUseISO8601;
  if AUseISO8601 then
    FFormat := 'yyyy-mm-dd"T"hh:nn:ss.zzz"Z"'
  else
    FFormat := '';
end;

{ JSONFloatFormatAttribute }

constructor JSONFloatFormatAttribute.Create(const ADecimalPlaces: Integer; const AUseDecimalSeparator: Boolean);
begin
  inherited Create;
  FDecimalPlaces := ADecimalPlaces;
  FUseDecimalSeparator := AUseDecimalSeparator;
end;

{ JSONConverterAttribute }

constructor JSONConverterAttribute.Create(AConverterClass: TClass);
begin
  inherited Create;
  FConverterClass := AConverterClass;
end;

function JSONConverterAttribute.CreateConverter: IJSONPropertyConverter;
var
  LInstance: TObject;
begin
  if Assigned(FConverterClass) then
  begin
    LInstance := FConverterClass.Create;
    if Supports(LInstance, IJSONPropertyConverter, Result) then
      Exit
    else
      LInstance.Free;
  end;
  Result := nil;
end;

{ JSONOrderAttribute }

constructor JSONOrderAttribute.Create(const AOrder: Integer);
begin
  inherited Create;
  FOrder := AOrder;
end;

{ JSONArrayAttribute }

constructor JSONArrayAttribute.Create(const AIncludeEmpty: Boolean; const AItemName: string);
begin
  inherited Create;
  FIncludeEmpty := AIncludeEmpty;
  FItemName := AItemName;
end;

{ JSONValidationAttribute }

constructor JSONValidationAttribute.Create(const AMinLength, AMaxLength: Integer; const APattern: string);
begin
  inherited Create;
  FMinLength := AMinLength;
  FMaxLength := AMaxLength;
  FPattern := APattern;
end;

{ TJSONAttributeHelper }

class function TJSONAttributeHelper.ShouldIgnoreProperty(const AProperty: TRttiProperty): Boolean;
var
  LAttr: TCustomAttribute;
begin
  Result := False;
  for LAttr in AProperty.GetAttributes do
  begin
    if LAttr is JSONIgnoreAttribute then
    begin
      Result := True;
      Break;
    end;
  end;
end;

class function TJSONAttributeHelper.GetJSONPropertyName(const AProperty: TRttiProperty): string;
var
  LAttr: TCustomAttribute;
begin
  Result := AProperty.Name; // Padrão
  
  for LAttr in AProperty.GetAttributes do
  begin
    if LAttr is JSONNameAttribute then
    begin
      Result := JSONNameAttribute(LAttr).Name;
      Break;
    end;
  end;
end;

class function TJSONAttributeHelper.ShouldIncludeValue(const AProperty: TRttiProperty; const AValue: TValue): Boolean;
var
  LAttr: TCustomAttribute;
  LIncludeAttr: JSONIncludeAttribute;
begin
  Result := True; // Padrão: incluir
  
  for LAttr in AProperty.GetAttributes do
  begin
    if LAttr is JSONIncludeAttribute then
    begin
      LIncludeAttr := JSONIncludeAttribute(LAttr);
      
      // Verificar null
      if AValue.IsEmpty and not LIncludeAttr.IncludeNull then
      begin
        Result := False;
        Break;
      end;
      
      // Verificar vazio (string, array)
      if not LIncludeAttr.IncludeEmpty then
      begin
        case AValue.Kind of
          tkString, tkLString, tkWString, tkUString:
            if AValue.AsString = '' then
            begin
              Result := False;
              Break;
            end;
          tkDynArray:
            if AValue.GetArrayLength = 0 then
            begin
              Result := False;
              Break;
            end;
        end;
      end;
    end;
  end;
end;

class function TJSONAttributeHelper.GetDateTimeFormat(const AProperty: TRttiProperty; out AFormat: string; out AUseISO8601: Boolean): Boolean;
var
  LAttr: TCustomAttribute;
begin
  Result := False;
  AFormat := '';
  AUseISO8601 := True; // Padrão
  
  for LAttr in AProperty.GetAttributes do
  begin
    if LAttr is JSONDateTimeFormatAttribute then
    begin
      AFormat := JSONDateTimeFormatAttribute(LAttr).Format;
      AUseISO8601 := JSONDateTimeFormatAttribute(LAttr).UseISO8601;
      Result := True;
      Break;
    end;
  end;
end;

class function TJSONAttributeHelper.GetFloatFormat(const AProperty: TRttiProperty; out ADecimalPlaces: Integer; out AUseDecimalSeparator: Boolean): Boolean;
var
  LAttr: TCustomAttribute;
begin
  Result := False;
  ADecimalPlaces := -1;
  AUseDecimalSeparator := True;
  
  for LAttr in AProperty.GetAttributes do
  begin
    if LAttr is JSONFloatFormatAttribute then
    begin
      ADecimalPlaces := JSONFloatFormatAttribute(LAttr).DecimalPlaces;
      AUseDecimalSeparator := JSONFloatFormatAttribute(LAttr).UseDecimalSeparator;
      Result := True;
      Break;
    end;
  end;
end;

class function TJSONAttributeHelper.GetCustomConverter(const AProperty: TRttiProperty): IJSONPropertyConverter;
var
  LAttr: TCustomAttribute;
begin
  Result := nil;
  
  for LAttr in AProperty.GetAttributes do
  begin
    if LAttr is JSONConverterAttribute then
    begin
      Result := JSONConverterAttribute(LAttr).CreateConverter;
      Break;
    end;
  end;
end;

class function TJSONAttributeHelper.GetSerializationOrder(const AProperty: TRttiProperty): Integer;
var
  LAttr: TCustomAttribute;
begin
  Result := MaxInt; // Padrão: sem ordem específica
  
  for LAttr in AProperty.GetAttributes do
  begin
    if LAttr is JSONOrderAttribute then
    begin
      Result := JSONOrderAttribute(LAttr).Order;
      Break;
    end;
  end;
end;

class function TJSONAttributeHelper.IsRequiredProperty(const AProperty: TRttiProperty): Boolean;
var
  LAttr: TCustomAttribute;
begin
  Result := False;
  
  for LAttr in AProperty.GetAttributes do
  begin
    if LAttr is JSONRequiredAttribute then
    begin
      Result := True;
      Break;
    end;
  end;
end;

class function TJSONAttributeHelper.GetArraySettings(const AProperty: TRttiProperty; out AIncludeEmpty: Boolean; out AItemName: string): Boolean;
var
  LAttr: TCustomAttribute;
begin
  Result := False;
  AIncludeEmpty := True;
  AItemName := '';
  
  for LAttr in AProperty.GetAttributes do
  begin
    if LAttr is JSONArrayAttribute then
    begin
      AIncludeEmpty := JSONArrayAttribute(LAttr).IncludeEmpty;
      AItemName := JSONArrayAttribute(LAttr).ItemName;
      Result := True;
      Break;
    end;
  end;
end;

end.