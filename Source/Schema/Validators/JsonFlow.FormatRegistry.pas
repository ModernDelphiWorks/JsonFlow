{
  ------------------------------------------------------------------------------
  JsonFlow
  High-performance JSON serialization, dynamic manipulation, and Draft 7 Schema validation framework for Delphi and Lazarus.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------
}

{$include ../../JsonFlow.inc}

unit JsonFlow.FormatRegistry;

{
  JsonFlow4D - Format Registry
  
  Sistema de registro de validadores de formato plugáveis.
  Permite registrar validadores customizados para formatos específicos.
  
  Exemplo de uso:
    TFormatRegistry.RegisterValidator('custom-email', TCustomEmailValidator.Create);
    TFormatRegistry.RegisterValidator('cpf', TCPFValidator.Create);
  
  Autor: JsonFlow4D Framework
  Data: 2024
}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections;

type
  // Interface para validadores de formato customizados
  IFormatValidator = interface
    ['{B8E5F2A1-9C3D-4E7F-8A2B-1D5C6E9F0A3B}']
    function Validate(const AValue: string): Boolean;
    function GetErrorMessage(const AValue: string): string;
    function GetFormatName: string;
  end;

  // Classe base para validadores de formato
  TBaseFormatValidator = class(TInterfacedObject, IFormatValidator)
  private
    FFormatName: string;
  protected
    function DoValidate(const AValue: string): Boolean; virtual; abstract;
    function GetDefaultErrorMessage(const AValue: string): string; virtual;
  public
    constructor Create(const AFormatName: string);
    function Validate(const AValue: string): Boolean;
    function GetErrorMessage(const AValue: string): string; virtual;
    function GetFormatName: string;
  end;

  // Registry singleton para gerenciar validadores de formato
  TFormatRegistry = class
  private
    class var FInstance: TFormatRegistry;
    class var FValidators: TDictionary<string, IFormatValidator>;
    class constructor Create;
    class destructor Destroy;
    constructor Create;
  public
    class function Instance: TFormatRegistry;
    class procedure RegisterValidator(const AFormatName: string; const AValidator: IFormatValidator);
    class procedure UnregisterValidator(const AFormatName: string);
    class function GetValidator(const AFormatName: string): IFormatValidator;
    class function IsFormatRegistered(const AFormatName: string): Boolean;
    class function GetRegisteredFormats: TArray<string>;
    class procedure ClearRegistry;
  end;

  // Validadores built-in usando o novo sistema
  TEmailFormatValidator = class(TBaseFormatValidator)
  protected
    function DoValidate(const AValue: string): Boolean; override;
  public
    constructor Create;
  end;

  TUriFormatValidator = class(TBaseFormatValidator)
  protected
    function DoValidate(const AValue: string): Boolean; override;
  public
    constructor Create;
  end;

  TDateFormatValidator = class(TBaseFormatValidator)
  protected
    function DoValidate(const AValue: string): Boolean; override;
  public
    constructor Create;
  end;

  TTimeFormatValidator = class(TBaseFormatValidator)
  protected
    function DoValidate(const AValue: string): Boolean; override;
  public
    constructor Create;
  end;

  TDateTimeFormatValidator = class(TBaseFormatValidator)
  protected
    function DoValidate(const AValue: string): Boolean; override;
  public
    constructor Create;
  end;

  TUuidFormatValidator = class(TBaseFormatValidator)
  protected
    function DoValidate(const AValue: string): Boolean; override;
  public
    constructor Create;
  end;

  TIpv4FormatValidator = class(TBaseFormatValidator)
  protected
    function DoValidate(const AValue: string): Boolean; override;
  public
    constructor Create;
  end;

  TIpv6FormatValidator = class(TBaseFormatValidator)
  protected
    function DoValidate(const AValue: string): Boolean; override;
  public
    constructor Create;
  end;

// Procedimento para registrar todos os validadores built-in
procedure RegisterBuiltInFormatValidators;

implementation

uses
  System.RegularExpressions;

{ TBaseFormatValidator }

constructor TBaseFormatValidator.Create(const AFormatName: string);
begin
  inherited Create;
  FFormatName := AFormatName;
end;

function TBaseFormatValidator.Validate(const AValue: string): Boolean;
begin
  Result := DoValidate(AValue);
end;

function TBaseFormatValidator.GetErrorMessage(const AValue: string): string;
begin
  Result := GetDefaultErrorMessage(AValue);
end;

function TBaseFormatValidator.GetDefaultErrorMessage(const AValue: string): string;
begin
  Result := Format('String "%s" does not match format "%s"', [AValue, FFormatName]);
end;

function TBaseFormatValidator.GetFormatName: string;
begin
  Result := FFormatName;
end;

{ TFormatRegistry }

class constructor TFormatRegistry.Create;
begin
  FValidators := TDictionary<string, IFormatValidator>.Create;
  RegisterBuiltInFormatValidators;
end;

class destructor TFormatRegistry.Destroy;
begin
  FValidators.Free;
end;

constructor TFormatRegistry.Create;
begin
  inherited Create;
end;

class function TFormatRegistry.Instance: TFormatRegistry;
begin
  if not Assigned(FInstance) then
    FInstance := TFormatRegistry.Create;
  Result := FInstance;
end;

class procedure TFormatRegistry.RegisterValidator(const AFormatName: string; const AValidator: IFormatValidator);
var
  LFormatLower: string;
begin
  LFormatLower := AnsiLowerCase(AFormatName);
  FValidators.AddOrSetValue(LFormatLower, AValidator);
end;

class procedure TFormatRegistry.UnregisterValidator(const AFormatName: string);
var
  LFormatLower: string;
begin
  LFormatLower := AnsiLowerCase(AFormatName);
  FValidators.Remove(LFormatLower);
end;

class function TFormatRegistry.GetValidator(const AFormatName: string): IFormatValidator;
var
  LFormatLower: string;
begin
  LFormatLower := AnsiLowerCase(AFormatName);
  if not FValidators.TryGetValue(LFormatLower, Result) then
    Result := nil;
end;

class function TFormatRegistry.IsFormatRegistered(const AFormatName: string): Boolean;
var
  LFormatLower: string;
begin
  LFormatLower := AnsiLowerCase(AFormatName);
  Result := FValidators.ContainsKey(LFormatLower);
end;

class function TFormatRegistry.GetRegisteredFormats: TArray<string>;
begin
  Result := FValidators.Keys.ToArray;
end;

class procedure TFormatRegistry.ClearRegistry;
begin
  FValidators.Clear;
end;

{ TEmailFormatValidator }

constructor TEmailFormatValidator.Create;
begin
  inherited Create('email');
end;

function TEmailFormatValidator.DoValidate(const AValue: string): Boolean;
var
  LRegex: TRegEx;
begin
  LRegex := TRegEx.Create('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  Result := LRegex.IsMatch(AValue);
end;

{ TUriFormatValidator }

constructor TUriFormatValidator.Create;
begin
  inherited Create('uri');
end;

function TUriFormatValidator.DoValidate(const AValue: string): Boolean;
var
  LRegex: TRegEx;
begin
  LRegex := TRegEx.Create('^https?://[^\s/$.?#].[^\s]*$');
  Result := LRegex.IsMatch(AValue);
end;

{ TDateFormatValidator }

constructor TDateFormatValidator.Create;
begin
  inherited Create('date');
end;

function TDateFormatValidator.DoValidate(const AValue: string): Boolean;
var
  LRegex: TRegEx;
begin
  // Formato YYYY-MM-DD
  LRegex := TRegEx.Create('^\d{4}-\d{2}-\d{2}$');
  Result := LRegex.IsMatch(AValue);
end;

{ TTimeFormatValidator }

constructor TTimeFormatValidator.Create;
begin
  inherited Create('time');
end;

function TTimeFormatValidator.DoValidate(const AValue: string): Boolean;
var
  LRegex: TRegEx;
begin
  // Formato HH:MM:SS ou HH:MM:SS.sss
  LRegex := TRegEx.Create('^\d{2}:\d{2}:\d{2}(\.\d{3})?$');
  Result := LRegex.IsMatch(AValue);
end;

{ TDateTimeFormatValidator }

constructor TDateTimeFormatValidator.Create;
begin
  inherited Create('date-time');
end;

function TDateTimeFormatValidator.DoValidate(const AValue: string): Boolean;
var
  LRegex: TRegEx;
  LYear, LMonth, LDay, LHour, LMin, LSec: Integer;
  LDateTimeStr: string;
begin
  // Primeiro verifica o formato ISO 8601: YYYY-MM-DDTHH:MM:SS ou YYYY-MM-DDTHH:MM:SSZ
  LRegex := TRegEx.Create('^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?(Z|[+-]\d{2}:\d{2})?$');
  if not LRegex.IsMatch(AValue) then
    Exit(False);
  
  // Agora valida se é uma data/hora real válida
  try
    // Remove timezone info para validação básica
    LDateTimeStr := AValue;
    if LDateTimeStr.EndsWith('Z') then
      LDateTimeStr := LDateTimeStr.Substring(0, LDateTimeStr.Length - 1);
    
    // Remove timezone offset (+/-HH:MM)
    if (LDateTimeStr.Length > 19) and 
       ((LDateTimeStr[LDateTimeStr.Length - 5] = '+') or (LDateTimeStr[LDateTimeStr.Length - 5] = '-')) then
      LDateTimeStr := LDateTimeStr.Substring(0, LDateTimeStr.Length - 6);
    
    // Remove milissegundos se presentes
    if (LDateTimeStr.Length > 19) and (LDateTimeStr[20] = '.') then
      LDateTimeStr := LDateTimeStr.Substring(0, 19);
    
    // Extrai componentes da data/hora: YYYY-MM-DDTHH:MM:SS
    if LDateTimeStr.Length <> 19 then
      Exit(False);
      
    LYear := StrToIntDef(LDateTimeStr.Substring(0, 4), -1);
    LMonth := StrToIntDef(LDateTimeStr.Substring(5, 2), -1);
    LDay := StrToIntDef(LDateTimeStr.Substring(8, 2), -1);
    LHour := StrToIntDef(LDateTimeStr.Substring(11, 2), -1);
    LMin := StrToIntDef(LDateTimeStr.Substring(14, 2), -1);
    LSec := StrToIntDef(LDateTimeStr.Substring(17, 2), -1);
    
    // Valida ranges
    if (LYear < 1) or (LMonth < 1) or (LMonth > 12) or 
       (LDay < 1) or (LDay > 31) or (LHour < 0) or (LHour > 23) or
       (LMin < 0) or (LMin > 59) or (LSec < 0) or (LSec > 59) then
      Exit(False);
    
    // Valida se a data é válida (considera anos bissextos, etc.)
    var LDate, LTime: TDateTime;
    Result := TryEncodeDate(LYear, LMonth, LDay, LDate) and
              TryEncodeTime(LHour, LMin, LSec, 0, LTime);
  except
    Result := False;
  end;
end;

{ TUuidFormatValidator }

constructor TUuidFormatValidator.Create;
begin
  inherited Create('uuid');
end;

function TUuidFormatValidator.DoValidate(const AValue: string): Boolean;
var
  LRegex: TRegEx;
begin
  LRegex := TRegEx.Create('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
  Result := LRegex.IsMatch(AValue);
end;

{ TIpv4FormatValidator }

constructor TIpv4FormatValidator.Create;
begin
  inherited Create('ipv4');
end;

function TIpv4FormatValidator.DoValidate(const AValue: string): Boolean;
var
  LRegex: TRegEx;
begin
  LRegex := TRegEx.Create('^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$');
  Result := LRegex.IsMatch(AValue);
end;

{ TIpv6FormatValidator }

constructor TIpv6FormatValidator.Create;
begin
  inherited Create('ipv6');
end;

function TIpv6FormatValidator.DoValidate(const AValue: string): Boolean;
var
  LRegex: TRegEx;
begin
  LRegex := TRegEx.Create('^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$');
  Result := LRegex.IsMatch(AValue);
end;

{ Registro dos validadores built-in }

procedure RegisterBuiltInFormatValidators;
begin
  TFormatRegistry.RegisterValidator('email', TEmailFormatValidator.Create);
  TFormatRegistry.RegisterValidator('uri', TUriFormatValidator.Create);
  TFormatRegistry.RegisterValidator('date', TDateFormatValidator.Create);
  TFormatRegistry.RegisterValidator('time', TTimeFormatValidator.Create);
  TFormatRegistry.RegisterValidator('date-time', TDateTimeFormatValidator.Create);
  TFormatRegistry.RegisterValidator('uuid', TUuidFormatValidator.Create);
  TFormatRegistry.RegisterValidator('ipv4', TIpv4FormatValidator.Create);
  TFormatRegistry.RegisterValidator('ipv6', TIpv6FormatValidator.Create);
end;

// Nota: O registro automático foi removido para evitar duplicação.
// Use JsonFlow.FormatValidators.RegisterAllFormatValidators para registrar os validadores.

end.
