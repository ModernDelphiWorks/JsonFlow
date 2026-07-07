{
  ------------------------------------------------------------------------------
  JsonFlow
  High-performance JSON serialization, dynamic manipulation, and Draft 7 Schema validation framework for Delphi.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------
}

unit JsonFlow.ValidationRules.Content;

interface

uses
  System.SysUtils, System.Classes, System.NetEncoding,
  JsonFlow.Interfaces, JsonFlow.ValidationEngine,
  JsonFlow.ValidationRules.Base;

type
  // Regra de validação para contentEncoding (base64, hex)
  TContentEncodingRule = class(TBaseValidationRule)
  private
    FEncoding: string;
    function IsValidBase64(const AValue: string): Boolean;
    function IsValidHex(const AValue: string): Boolean;
  public
    constructor Create(const AEncoding: string);
    function Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult; override;
  end;

  // Regra de validação para contentMediaType (ex: application/json)
  TContentMediaTypeRule = class(TBaseValidationRule)
  private
    FMediaType: string;
    function ValidateJSON(const AValue: string): Boolean;
  public
    constructor Create(const AMediaType: string);
    function Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult; override;
  end;

implementation

uses
  JsonFlow.Reader;

{ TContentEncodingRule }

constructor TContentEncodingRule.Create(const AEncoding: string);
begin
  inherited Create('contentEncoding');
  FEncoding := AEncoding.ToLower;
end;

function TContentEncodingRule.IsValidBase64(const AValue: string): Boolean;
var
  LChar: Char;
  LPadCount: Integer;
begin
  Result := False;
  if AValue.IsEmpty then
    Exit(True);

  LPadCount := 0;
  for LChar in AValue do
  begin
    if LChar = '=' then
    begin
      Inc(LPadCount);
      if LPadCount > 2 then
        Exit(False);
    end
    else
    begin
      if LPadCount > 0 then
        Exit(False); // Padding deve estar apenas no final

      case LChar of
        'A'..'Z', 'a'..'z', '0'..'9', '+', '/': ; // Válidos
      else
        Exit(False);
      end;
    end;
  end;

  // Tamanho do base64 deve ser múltiplo de 4
  Result := (AValue.Length mod 4) = 0;
end;

function TContentEncodingRule.IsValidHex(const AValue: string): Boolean;
var
  LChar: Char;
begin
  Result := False;
  if AValue.IsEmpty then
    Exit(True);

  if (AValue.Length mod 2) <> 0 then
    Exit(False);

  for LChar in AValue do
  begin
    case LChar of
      '0'..'9', 'a'..'f', 'A'..'F': ; // Válidos
    else
      Exit(False);
    end;
  end;

  Result := True;
end;

function TContentEncodingRule.Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult;
var
  LValidationContext: TValidationContext;
  LValue: IJSONValue;
  LStringValue: string;
  LIsValid: Boolean;
begin
  LValidationContext := TValidationContext(AContext);

  // JSON Schema especifica que contentEncoding aplica-se apenas a strings
  if not Supports(AValue, IJSONValue, LValue) or not LValue.IsString then
  begin
    Result := TValidationResult.Success(LValidationContext.GetFullPath);
    Exit;
  end;

  LStringValue := LValue.AsString;
  LIsValid := True;

  if FEncoding = 'base64' then
  begin
    LIsValid := IsValidBase64(LStringValue);
  end
  else if FEncoding = 'hex' then
  begin
    LIsValid := IsValidHex(LStringValue);
  end;

  if not LIsValid then
  begin
    Result := TValidationResult.Failure(
      LValidationContext.GetFullPath,
      [CreateValidationError(
        LValidationContext.GetFullPath,
        Format('Value is not a valid %s encoded string', [FEncoding]),
        LStringValue,
        FEncoding,
        'contentEncoding',
        LValidationContext.GetFullSchemaPath + '/contentEncoding'
      )]
    );
  end
  else
    Result := TValidationResult.Success(LValidationContext.GetFullPath);
end;

{ TContentMediaTypeRule }

constructor TContentMediaTypeRule.Create(const AMediaType: string);
begin
  inherited Create('contentMediaType');
  FMediaType := AMediaType.ToLower;
end;

function TContentMediaTypeRule.ValidateJSON(const AValue: string): Boolean;
var
  LReader: TJSONReader;
begin
  Result := False;
  LReader := TJSONReader.Create;
  try
    try
      LReader.Read(AValue);
      Result := True;
    except
      Result := False;
    end;
  finally
    LReader.Free;
  end;
end;

function TContentMediaTypeRule.Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult;
var
  LValidationContext: TValidationContext;
  LValue: IJSONValue;
  LRawValue: string;
  LDecodedValue: string;
  LSchemaObj: IJSONObject;
  LContentEncoding: string;
  LIsValid: Boolean;
begin
  LValidationContext := TValidationContext(AContext);

  if not Supports(AValue, IJSONValue, LValue) or not LValue.IsString then
  begin
    Result := TValidationResult.Success(LValidationContext.GetFullPath);
    Exit;
  end;

  LRawValue := LValue.AsString;
  LDecodedValue := LRawValue;

  // Checar se há contentEncoding no schema irmão para decodificar antes de validar o mediaType
  LContentEncoding := '';
  if Assigned(LValidationContext.Schema) and Supports(LValidationContext.Schema, IJSONObject, LSchemaObj) then
  begin
    if LSchemaObj.ContainsKey('contentEncoding') then
      LContentEncoding := (LSchemaObj.GetValue('contentEncoding') as IJSONValue).AsString.ToLower;
  end;

  // Pré-decodificar se necessário
  if LContentEncoding = 'base64' then
  begin
    try
      LDecodedValue := TNetEncoding.Base64.Decode(LRawValue);
    except
      // Se falhar na decodificação, a validação de media type falha
      LIsValid := False;
    end;
  end
  else if LContentEncoding = 'hex' then
  begin
    try
      var LBytes: TBytes;
      SetLength(LBytes, LRawValue.Length div 2);
      for var LFor := 0 to Length(LBytes) - 1 do
        LBytes[LFor] := StrToInt('$' + LRawValue.Substring(LFor * 2, 2));
      LDecodedValue := TEncoding.UTF8.GetString(LBytes);
    except
      LIsValid := False;
    end;
  end;

  LIsValid := True;

  if FMediaType = 'application/json' then
  begin
    LIsValid := ValidateJSON(LDecodedValue);
  end;

  if not LIsValid then
  begin
    Result := TValidationResult.Failure(
      LValidationContext.GetFullPath,
      [CreateValidationError(
        LValidationContext.GetFullPath,
        Format('Value does not conform to media type "%s"', [FMediaType]),
        LRawValue,
        FMediaType,
        'contentMediaType',
        LValidationContext.GetFullSchemaPath + '/contentMediaType'
      )]
    );
  end
  else
    Result := TValidationResult.Success(LValidationContext.GetFullPath);
end;

end.
