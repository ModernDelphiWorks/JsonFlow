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
  System.RegularExpressions,
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
    // Protege o dicionário: registro/consulta concorrentes (validações em
    // threads distintas) corrompiam o TDictionary sem sincronização.
    class var FLock: TObject;
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

  // Base para validadores de regex fixa: compila o padrão UMA vez no
  // constructor (os validadores são singletons de vida longa no registry;
  // antes cada DoValidate criava e compilava um TRegEx novo por valor).
  TRegexFormatValidator = class(TBaseFormatValidator)
  private
    FRegex: TRegEx;
  protected
    function DoValidate(const AValue: string): Boolean; override;
  public
    constructor Create(const AFormatName, APattern: string);
  end;

  // Validadores built-in usando o novo sistema
  TEmailFormatValidator = class(TRegexFormatValidator)
  public
    constructor Create;
  end;

  TUriFormatValidator = class(TRegexFormatValidator)
  public
    constructor Create;
  end;

  TDateFormatValidator = class(TRegexFormatValidator)
  public
    constructor Create;
  end;

  TTimeFormatValidator = class(TRegexFormatValidator)
  public
    constructor Create;
  end;

  TDateTimeFormatValidator = class(TBaseFormatValidator)
  private
    FRegex: TRegEx;
  protected
    function DoValidate(const AValue: string): Boolean; override;
  public
    constructor Create;
  end;

  TUuidFormatValidator = class(TRegexFormatValidator)
  public
    constructor Create;
  end;

  TIpv4FormatValidator = class(TRegexFormatValidator)
  public
    constructor Create;
  end;

  TIpv6FormatValidator = class(TRegexFormatValidator)
  public
    constructor Create;
  end;

// Procedimento para registrar todos os validadores built-in
procedure RegisterBuiltInFormatValidators;

implementation

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
  FLock := TObject.Create;
  FValidators := TDictionary<string, IFormatValidator>.Create;
  // Instância criada aqui (eager) para eliminar o lazy-init com race no Instance
  FInstance := TFormatRegistry.Create;
  RegisterBuiltInFormatValidators;
end;

class destructor TFormatRegistry.Destroy;
begin
  FInstance.Free;
  FValidators.Free;
  FLock.Free;
end;

constructor TFormatRegistry.Create;
begin
  inherited Create;
end;

class function TFormatRegistry.Instance: TFormatRegistry;
begin
  Result := FInstance;
end;

class procedure TFormatRegistry.RegisterValidator(const AFormatName: string; const AValidator: IFormatValidator);
begin
  TMonitor.Enter(FLock);
  try
    FValidators.AddOrSetValue(AnsiLowerCase(AFormatName), AValidator);
  finally
    TMonitor.Exit(FLock);
  end;
end;

class procedure TFormatRegistry.UnregisterValidator(const AFormatName: string);
begin
  TMonitor.Enter(FLock);
  try
    FValidators.Remove(AnsiLowerCase(AFormatName));
  finally
    TMonitor.Exit(FLock);
  end;
end;

class function TFormatRegistry.GetValidator(const AFormatName: string): IFormatValidator;
begin
  TMonitor.Enter(FLock);
  try
    if not FValidators.TryGetValue(AnsiLowerCase(AFormatName), Result) then
      Result := nil;
  finally
    TMonitor.Exit(FLock);
  end;
end;

class function TFormatRegistry.IsFormatRegistered(const AFormatName: string): Boolean;
begin
  TMonitor.Enter(FLock);
  try
    Result := FValidators.ContainsKey(AnsiLowerCase(AFormatName));
  finally
    TMonitor.Exit(FLock);
  end;
end;

class function TFormatRegistry.GetRegisteredFormats: TArray<string>;
begin
  TMonitor.Enter(FLock);
  try
    Result := FValidators.Keys.ToArray;
  finally
    TMonitor.Exit(FLock);
  end;
end;

class procedure TFormatRegistry.ClearRegistry;
begin
  TMonitor.Enter(FLock);
  try
    FValidators.Clear;
  finally
    TMonitor.Exit(FLock);
  end;
end;

{ TRegexFormatValidator }

constructor TRegexFormatValidator.Create(const AFormatName, APattern: string);
begin
  inherited Create(AFormatName);
  FRegex := TRegEx.Create(APattern, [roCompiled]);
  if FRegex.IsMatch('') then; // força a compilação lazy fora do hot path // força a compilação lazy aqui, não no hot path
end;

function TRegexFormatValidator.DoValidate(const AValue: string): Boolean;
begin
  Result := FRegex.IsMatch(AValue);
end;

{ TEmailFormatValidator }

constructor TEmailFormatValidator.Create;
begin
  inherited Create('email', '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
end;

{ TUriFormatValidator }

constructor TUriFormatValidator.Create;
begin
  inherited Create('uri', '^https?://[^\s/$.?#].[^\s]*$');
end;

{ TDateFormatValidator }

constructor TDateFormatValidator.Create;
begin
  // Formato YYYY-MM-DD
  inherited Create('date', '^\d{4}-\d{2}-\d{2}$');
end;

{ TTimeFormatValidator }

constructor TTimeFormatValidator.Create;
begin
  // Formato HH:MM:SS ou HH:MM:SS.sss
  inherited Create('time', '^\d{2}:\d{2}:\d{2}(\.\d{3})?$');
end;

{ TDateTimeFormatValidator }

constructor TDateTimeFormatValidator.Create;
begin
  inherited Create('date-time');
  // Formato ISO 8601: YYYY-MM-DDTHH:MM:SS ou YYYY-MM-DDTHH:MM:SSZ
  FRegex := TRegEx.Create('^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?(Z|[+-]\d{2}:\d{2})?$', [roCompiled]);
  if FRegex.IsMatch('') then; // força a compilação lazy fora do hot path
end;

function TDateTimeFormatValidator.DoValidate(const AValue: string): Boolean;
var
  LYear, LMonth, LDay, LHour, LMin, LSec: Integer;
  LDateTimeStr: string;
begin
  if not FRegex.IsMatch(AValue) then
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
  inherited Create('uuid', '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
end;

{ TIpv4FormatValidator }

constructor TIpv4FormatValidator.Create;
begin
  inherited Create('ipv4', '^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$');
end;

{ TIpv6FormatValidator }

constructor TIpv6FormatValidator.Create;
begin
  inherited Create('ipv6', '^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$');
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
