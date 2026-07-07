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

{$include ../../../JsonFlow.inc}
unit JsonFlow.FormatValidators.DateTime;

interface

uses
  System.SysUtils,
  System.RegularExpressions,
  JsonFlow.FormatValidators.Base;

type
  TDateTimeFormatValidator = class(TBaseFormatValidatorPlugin)
  protected
    function DoValidate(const AValue: string): Boolean; override;
    function GetCustomErrorMessage(const AValue: string): string; override;
  public
    constructor Create;
  end;

  // Função para registrar o validador
  procedure RegisterDateTimeValidator;

implementation

uses
  JsonFlow.FormatRegistry;

var
  // Regexes compiladas UMA vez no load da unit (antes: TRegEx.Create
  // por valor validado dentro do DoValidate)
  GRegex1: TRegEx;

{ TDateTimeFormatValidator }

constructor TDateTimeFormatValidator.Create;
begin
  inherited Create('date-time', 'String does not match ISO 8601 date-time format');
end;

function TDateTimeFormatValidator.DoValidate(const AValue: string): Boolean;
var
  LRegex: TRegEx;
  LYear, LMonth, LDay, LHour, LMinute, LSecond: Integer;
  LDate, LTime: TDateTime;
  LDateTimeStr: string;
  LPos: Integer;
begin
  if AValue.IsEmpty then
  begin
    Result := False;
    Exit;
  end;
  
  // Primeiro verifica o formato ISO 8601
  LRegex := GRegex1;
  if not LRegex.IsMatch(AValue) then
  begin
    Result := False;
    Exit;
  end;
  
  // Remove timezone e milissegundos para validação básica
  LDateTimeStr := AValue;
  if LDateTimeStr.Contains('Z') then
    LDateTimeStr := Copy(LDateTimeStr, 1, LDateTimeStr.IndexOf('Z'));
  if LDateTimeStr.Contains('+') then
    LDateTimeStr := Copy(LDateTimeStr, 1, LDateTimeStr.IndexOf('+'));
  // Procura por '-' após a posição 10 para evitar o '-' da data
  LPos := Pos('-', Copy(LDateTimeStr, 11, Length(LDateTimeStr)));
  if LPos > 0 then
    LDateTimeStr := Copy(LDateTimeStr, 1, 10 + LPos - 1);
  if LDateTimeStr.Contains('.') then
    LDateTimeStr := Copy(LDateTimeStr, 1, LDateTimeStr.IndexOf('.'));
  
  // Extrai componentes: YYYY-MM-DDTHH:MM:SS
  try
    LYear := StrToInt(Copy(LDateTimeStr, 1, 4));
    LMonth := StrToInt(Copy(LDateTimeStr, 6, 2));
    LDay := StrToInt(Copy(LDateTimeStr, 9, 2));
    LHour := StrToInt(Copy(LDateTimeStr, 12, 2));
    LMinute := StrToInt(Copy(LDateTimeStr, 15, 2));
    LSecond := StrToInt(Copy(LDateTimeStr, 18, 2));
    
    // Valida ranges básicos
    if (LMonth < 1) or (LMonth > 12) then
    begin
      Result := False;
      Exit;
    end;
    
    if (LDay < 1) or (LDay > 31) then
    begin
      Result := False;
      Exit;
    end;
    
    if (LHour < 0) or (LHour > 23) then
    begin
      Result := False;
      Exit;
    end;
    
    if (LMinute < 0) or (LMinute > 59) then
    begin
      Result := False;
      Exit;
    end;
    
    if (LSecond < 0) or (LSecond > 59) then
    begin
      Result := False;
      Exit;
    end;
    
    // Valida se a data é válida (considera anos bissextos, etc.)
    if not TryEncodeDate(LYear, LMonth, LDay, LDate) then
    begin
      Result := False;
      Exit;
    end;
    
    // Valida se o tempo é válido
    if not TryEncodeTime(LHour, LMinute, LSecond, 0, LTime) then
    begin
      Result := False;
      Exit;
    end;
    
    Result := True;
  except
    Result := False;
  end;
end;

function TDateTimeFormatValidator.GetCustomErrorMessage(const AValue: string): string;
var
  LRegex: TRegEx;
begin
  if AValue.IsEmpty then
    Result := 'Date-time cannot be empty'
  else
  begin
    LRegex := GRegex1;
    if not LRegex.IsMatch(AValue) then
      Result := Format('String "%s" does not match ISO 8601 date-time format (YYYY-MM-DDTHH:MM:SS[.sss][Z|±HH:MM])', [AValue])
    else
      Result := Format('Date-time "%s" contains invalid date or time components', [AValue]);
  end;
end;

// Função para registrar o validador
procedure RegisterDateTimeValidator;
begin
  TFormatRegistry.RegisterValidator('date-time', TDateTimeFormatValidator.Create);
end;

initialization
  GRegex1 := TRegEx.Create('^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?(Z|[+-]\d{2}:\d{2})?$');

end.
